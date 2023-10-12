# flo-kafka-connect-s3-connector
Flo Kafka Connect S3 Connector for Telemetry Data
Initial version 7/23/18 jcs

Creates partitions using the connect-s3-sink.properties:

  partition.field.timestamp=ts
  partition.field.name=did,ts
  path.format = yyyy/MM/dd

The output on S3 is constructed as follows, where 'did' is the device id string, and 'ts' is a 64-bit UTC timestamp
converted into the date-time format as specified by path.format. Example output on S3:

  topics/flo-telemetry/f87aef0100ce/2018/06/29/flo-telemetry+0+0000000078.avro

If partition.field.name=ts,did, the date would be ordered first, followed by the device id.

See FloPartitioner.java for core functionality.

*** Testing ***

Install the Confluent 4.1.1 files locally, e.g download the zip, extract, and add to the path
<path-to-confluent>/bin

Create the Amazon S3 credential file ~/.aws/credentials (add the correct values after = )
[default]
aws_access_key_id=
aws_secret_access_key=

Run:

confluent start
confluent stop connect

Add the Flo schema:

kafka-avro-console-producer --broker-list localhost:9092 --topic flo-telemetry --property value.schema='{ "name": "tlmbdl", "type": "record", "fields": [ {"name": "did", "type": "string"}, {"name": "ts1st", "type": "long"}, { "name": "tlms", "type": { "type": "array", "items": { "name": "tlm", "type": "record", "fields" : [ {"name": "ts", "type": "long"}, {"name": "fr", "type": "double"}, {"name": "fv", "type": "double"}, {"name": "p", "type": "double"}, {"name": "t", "type": "double"}, {"name": "v", "type": "int"}, {"name": "rssi", "type": "double"}, {"name": "sm", "type": "int"} ] } } } ] }
'

Paste in as many of these as desired (must all be the same schema/format):

{"did" : "f87aef0100ce","ts1st" : 1530311958112,"tlms" : [{"ts" : 1530311958112,"fr" : 1.23,"fv" : 4.56,"p" : 7.89,"t" : 72.34,"v" : 0,"rssi" : 8.91,"sm" : 1},{"ts" : 1530311959112,"fr" : 2.34,"fv" : 5.67,"p" : 8.92,"t" : 75.67,"v" : 1,"rssi" : 9.01,"sm" : 0}]}

Hit Control-C to finish.

Run:

./build-and-test.sh

Debug output will show the records being sent to S3. Use any S3 tool or web browser to verify partitioning
with Avro files written to the correct locations.

Run:

confluent destroy

to stop all Confluent processes and clean up files.