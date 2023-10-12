package flo.directive.router.utils

import java.io._
import java.security.cert.{Certificate, CertificateFactory, X509Certificate}
import java.security.spec.PKCS8EncodedKeySpec
import java.security.{KeyFactory, KeyStore}
import javax.net.ssl.{KeyManagerFactory, SSLContext, SSLSocketFactory, TrustManagerFactory}
import com.amazonaws.regions.{Region, Regions}
import com.amazonaws.services.s3.AmazonS3Client
import com.amazonaws.services.s3.model.GetObjectRequest
import com.typesafe.scalalogging.LazyLogging
import org.apache.commons.codec.binary.Base64
import sun.security.provider.X509Factory

class MQTTSecurityProvider(bucketName: String, sSLConfiguration: SSLConfiguration)
  extends IMQTTSecurityProvider with LazyLogging {

  private val client = new AmazonS3Client()
  private val s3Region = Region.getRegion(Regions.US_WEST_2)

  client.setRegion(s3Region)

  //Load client certificate
  val clientCertificate = getCertificate(getFileFromS3(sSLConfiguration.clientCert))

  //Load Certificate Authority (CA) certificate
  val brokerCaCertificate = getCertificate(getFileFromS3(sSLConfiguration.brokerCaCertificate))

  //Load client private key
  val clientPrivateKey = Base64.decodeBase64(
    getFileFromS3(sSLConfiguration.clientKey)
      .stripPrefix("-----BEGIN RSA PRIVATE KEY-----")
      .stripSuffix("-----END RSA PRIVATE KEY-----")
  )

  private def getFileFromS3(key: String): String = {
    /*
   * Download an object - When you download an object, you get all of
   * the object's metadata and a stream from which to read the contents.
   * It's important to read the contents of the stream as quickly as
   * possibly since the data is streamed directly from Amazon S3 and your
   * network connection will remain open until you read all the data or
   * close the input stream.
   *
   * GetObjectRequest also supports several other options, including
   * conditional downloading of objects based on modification times,
   * ETags, and selectively downloading a range of an object.
   */
    val s3Object = client.getObject(new GetObjectRequest(bucketName, key))
    val input = s3Object.getObjectContent()
    val reader = new BufferedReader(new InputStreamReader(input))
    val appender = new StringBuilder

    val iterator = reader.lines().iterator()

    while (iterator.hasNext) {
      appender ++= iterator.next()
    }

    logger.info(s"File with key $key downloaded from S3")

    appender.toString()
  }

  def getCertificate(certInString: String): X509Certificate = {
    val certificateFactory = CertificateFactory.getInstance("X.509")
    val decodedCert = Base64.decodeBase64(
      certInString.stripPrefix(X509Factory.BEGIN_CERT).stripSuffix(X509Factory.END_CERT)
    )

    val inputStream = new ByteArrayInputStream(decodedCert)

    certificateFactory
      .generateCertificate(inputStream)
      .asInstanceOf[X509Certificate]
  }

  def getSocketFactory(): SSLSocketFactory = {
    /**
      * CA certificate is used to authenticate server
      */
    val caKeyStore = KeyStore.getInstance(KeyStore.getDefaultType())
    caKeyStore.load(null, null)
    caKeyStore.setCertificateEntry("ca-certificate", brokerCaCertificate)

    val trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
    trustManagerFactory.init(caKeyStore)

    /**
      * Client key and certificates are sent to server so it can authenticate the client
      */

    val clientKeyStore = KeyStore.getInstance(KeyStore.getDefaultType())
    clientKeyStore.load(null, null)
    clientKeyStore.setCertificateEntry("certificate", clientCertificate)
    val certArray = Array(clientCertificate.asInstanceOf[Certificate])
    val keySpec = new PKCS8EncodedKeySpec(clientPrivateKey)
    val keyFactory = KeyFactory.getInstance("RSA")
    val privateKey = keyFactory.generatePrivate(keySpec)

    clientKeyStore.setKeyEntry("private-key", privateKey, new Array[Char](0), certArray)

    val keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())

    //TODO: second parameter should not be null
    keyManagerFactory.init(clientKeyStore, new Array[Char](0))

    /**
      * Create SSL socket factory
      */
    val context = SSLContext.getInstance("TLSv1.2")
    context.init(keyManagerFactory.getKeyManagers(), trustManagerFactory.getTrustManagers(), null)

    /**
      * Return the newly created socket factory object
      */
    context.getSocketFactory()
  }
}


trait IMQTTSecurityProvider {
  def getSocketFactory(): SSLSocketFactory
}