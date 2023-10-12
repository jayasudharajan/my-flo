package main

import (
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io/ioutil"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/labstack/gommon/log"
)

const mqttConnectWaitTime = 3000
const clientCertPath = "certs/client-cert.pem"
const clientPrivateKeyPath = "certs/client-key.pem"
const caCertPath = "certs/flo-ca-certificate.pem"

var _floMqttBroker string

// MqttPublisherClient is an MQTT publisher client
var MqttPublisherClient mqtt.Client

// InitMqttPublisher initializes publisher MQTT client
func InitMqttPublisher() (mqtt.Client, error) {
	clientId := createMqttClientId()
	return initMqttClient(clientId)
}

// initMqttClient initializes MQTT client
func initMqttClient(clientId string) (mqtt.Client, error) {
	tlsConfig, err := createNewTLSConfig()
	if err != nil {
		return nil, err
	}
	brokerUrl := getEnvOrExit("FLO_MQTT_BROKER")
	ops := mqtt.NewClientOptions().SetClientID(clientId).AddBroker(brokerUrl).SetTLSConfig(tlsConfig).SetCleanSession(true)
	MqttPublisherClient = mqtt.NewClient(ops)

	start := MqttPublisherClient.Connect().WaitTimeout(time.Millisecond * mqttConnectWaitTime)
	if !start {
		return nil, fmt.Errorf("failed to initialize %s MQTT client", clientId)
	}
	_floMqttBroker = brokerUrl

	log.Infof("MQTT client %s has been initialized, connected to %s broker", clientId, brokerUrl)
	return MqttPublisherClient, nil
}

func createMqttClientId() string {
	// only up to 23 characters is allowed for the clientId (this restriction might be old though)
	n := 11
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		panic(err)
	}
	return fmt.Sprintf("%x", b)
}

func createNewTLSConfig() (*tls.Config, error) {

	// Import client certificate/key pair
	// TODO: put these certs path values in the init_config.go
	cert, err := tls.LoadX509KeyPair(clientCertPath, clientPrivateKeyPath)
	if err != nil {
		return nil, err
	}
	// Just to print out the client certificate..
	cert.Leaf, err = x509.ParseCertificate(cert.Certificate[0])
	if err != nil {
		log.Fatalf("certs have invalid format, err: %v", err)
	}

	// Load CA cert
	caCert, err := ioutil.ReadFile(caCertPath)
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// Create tls.Config with desired tls properties
	return &tls.Config{
		Rand: nil,
		Time: nil,
		// Certificates = list of certs client sends to server.
		Certificates:          []tls.Certificate{cert},
		NameToCertificate:     nil,
		GetCertificate:        nil,
		GetClientCertificate:  nil,
		GetConfigForClient:    nil,
		VerifyPeerCertificate: nil,
		RootCAs:               nil,
		NextProtos:            nil,
		ServerName:            "",
		// ClientAuth = whether to request cert from server.
		// Since the server is set up for SSL, this happens
		// anyways.
		ClientAuth: tls.RequireAnyClientCert,
		// ClientCAs = certs used to validate client cert.
		ClientCAs: caCertPool,
		// InsecureSkipVerify = verify that cert contents
		// match server. IP matches what is in cert etc.
		InsecureSkipVerify: true,
	}, nil
}
