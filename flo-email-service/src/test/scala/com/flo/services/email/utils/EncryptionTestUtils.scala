package com.flo.services.email.utils

import java.io.{DataInputStream, File, FileInputStream}
import com.flo.encryption.FLOCipher

trait EncryptionTestUtils {
  val pathToKeys = "/"
  val publicKeyFile = pathToKeys + "public_key"
  val privateKeyFile = pathToKeys + "private_key"

  val publicKey = getKey(publicKeyFile)
  val privateKey = getKey(privateKeyFile)

  val cipher = new FLOCipher

  def getKey(filename: String): String = {
    val f = new File(getClass.getResource(filename).getPath)
    val fis = new FileInputStream(f)
    val dis = new DataInputStream(fis)
    val keyBytes = new Array[Byte](f.length().toInt)
    dis.readFully(keyBytes)
    dis.close()

    val key = new String(keyBytes)

    key
      .replace("-----BEGIN PUBLIC KEY-----", "")
      .replace("-----END PUBLIC KEY-----", "")
      .replace("-----BEGIN RSA PRIVATE KEY-----", "")
      .replace("-----END RSA PRIVATE KEY-----", "")
      .trim
  }
}
