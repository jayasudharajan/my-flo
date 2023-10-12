#!/usr/bin/env bash
# outputs the jar for your partitioner: target/kafka-connect-s3-custom-partitioner-1.0-SNAPSHOT.jar
mvn clean package
#-DskipTests

# Files will be copied here automatically
mkdir -p connectors/s3-connector/
# clean the connectors dir
rm connectors/s3-connector/*

# move to the s3 directory
cp target/kafka-connect-s3-flo-partitioner-1.0-SNAPSHOT.jar connectors/s3-connector/flo-custom-partitioner.jar

# remove some unneeded dependencies
rm target/kafka-connect-s3-custom-partitioner-1.0-SNAPSHOT.lib/kafka-clients-1.1.0.jar
rm target/kafka-connect-s3-custom-partitioner-1.0-SNAPSHOT.lib/zkclient-0.10.jar
rm target/kafka-connect-s3-custom-partitioner-1.0-SNAPSHOT.lib/connect-api-1.1.0.jar
rm target/kafka-connect-s3-custom-partitioner-1.0-SNAPSHOT.lib/zookeeper-3.4.10.jar

# move the rest
cp target/kafka-connect-s3-flo-partitioner-1.0-SNAPSHOT.lib/* connectors/s3-connector

# run the jar
connect-standalone config/connect-standalone.properties config/connect-s3-sink.properties
