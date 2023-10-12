package com.flotechnologies;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;
import org.apache.commons.io.IOUtils;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

public class S3EventListener implements RequestStreamHandler{
    private final String KAFKA_BOOTSTRAP_SERVERS_VAR = "KAFKA_HOST";
    private final String KAFKA_TOPIC_NAME_VAR = "KAFKA_TOPIC_NAME";

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException  {
        Optional<String> optionalTopicName = Optional.ofNullable(System.getenv(KAFKA_TOPIC_NAME_VAR));
        if (optionalTopicName.isPresent()) {
            String eventText = IOUtils.toString(input);
            String topicName = optionalTopicName.get();
            Producer<String, String > kafkaProducer = createKafkaProducer();

            try {
                kafkaProducer.send(
                        new ProducerRecord<>(topicName, eventText)
                ).get();
            } catch (InterruptedException | ExecutionException e){
                e.printStackTrace();
            }

            kafkaProducer.flush();
            kafkaProducer.close();


        } else {
            printMissingVariable(KAFKA_TOPIC_NAME_VAR);
            System.exit(1);
        }
    }

    private Producer<String, String> createKafkaProducer() {
        String kafkaHost;
        Properties p = new Properties();
        p.put("acks", "all");
        p.put("retries", 5);
        p.put("batch.size", 16384);
        p.put("linger.ms", 1);
        p.put("buffer.memory", 33554432);
        p.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        p.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        Optional<String> kafkaHostOptional = Optional.ofNullable(
                System.getenv(KAFKA_BOOTSTRAP_SERVERS_VAR)
        );
        if (kafkaHostOptional.isPresent()) {
            kafkaHost = kafkaHostOptional.get();
            p.put("bootstrap.servers", kafkaHost);
        } else {
            printMissingVariable(KAFKA_BOOTSTRAP_SERVERS_VAR);
            System.exit(1);
        }

        return new KafkaProducer<>(p);
    }

    private void printMissingVariable(String v) {
        System.err.println("Required variable " + v + " is not specified. Exiting...");
    }
}
