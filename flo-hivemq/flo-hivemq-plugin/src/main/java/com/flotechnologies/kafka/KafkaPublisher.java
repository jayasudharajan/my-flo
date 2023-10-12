package com.flotechnologies.kafka;

import com.flotechnologies.annotations.NonBlank;
import com.flotechnologies.configuration.KafkaConfiguration;
import com.google.inject.Inject;
import com.google.inject.Singleton;
import com.hivemq.spi.annotations.NotNull;
import com.hivemq.spi.services.PluginExecutorService;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import java.util.concurrent.ExecutorService;

import io.reactivex.Maybe;
import io.reactivex.annotations.CheckReturnValue;
import io.reactivex.schedulers.Schedulers;

@Singleton
public class KafkaPublisher {
    //@NotNull
    //private final Logger logger = LoggerFactory.getLogger(KafkaPublisher.class);

    @NotNull
    private final Producer<String, String> producer;
    @NotNull
    private final ExecutorService executorService;

    @Inject
    public KafkaPublisher(@NotNull final KafkaConfiguration kafkaConfiguration,
                          @NotNull final PluginExecutorService executorService) {
        // Workaround to fix : org.apache.kafka.common.config.ConfigException: Invalid value
        // org.apache.kafka.clients.producer.internals.DefaultPartitioner
        // for configuration partitioner.class:
        // Class org.apache.kafka.clients.producer.internals.DefaultPartitioner could not be found.
        ClassLoader ccl = Thread.currentThread().getContextClassLoader();
        Thread.currentThread().setContextClassLoader(null);
        producer = new KafkaProducer<>(kafkaConfiguration.getProperties());
        Thread.currentThread().setContextClassLoader(ccl);
        this.executorService = executorService;
    }

    /**
     * @param topic Kafka topic, DO NOT put empty
     * @param partitionKey Kafka message in json, DO NOT put empty
     * @param message Kafka message in json, DO NOT put empty
     * @return RecordMetadata RecordMetadata
     *
     * FutureReturnValueIgnored because we have putted the callback for listening returns and error
     */
    @NotNull
    @CheckReturnValue
    @SuppressWarnings("FutureReturnValueIgnored")
    public Maybe<RecordMetadata> publish(@NonBlank @NotNull final String topic,
                                         @NonBlank @NotNull final String partitionKey,
                                         @NonBlank @NotNull final String message) {
        // We didn't use Single<> instead of Maybe<>, because RecordMetadata is nullable.
        // And also we didn't use CompletableFuture,
        // because it doesn't provide emitter for the callback
        return Maybe.<RecordMetadata>create(it -> {
            // KafkaProducer.send() will
            // throws ExecutionException exception
            // throws InterruptException If the thread is interrupted while blocked
            // throws SerializationException If the key or value are not valid objects given the configured serializers
            // throws TimeoutException If the time taken for fetching metadata or allocating memory for the record has surpassed <code>max.block.ms</code>.
            // throws KafkaException If a Kafka related error occurs that does not belong to the public API exceptions.
            // here is no try-catch, the Maybe.create() will catch that and put it into the error workflow
            producer.send(new ProducerRecord<>(topic, partitionKey, message), (v, e) -> {
                if (it.isDisposed()) return;
                if (e != null) {
                    it.onError(e);
                } else {
                    if (v != null) it.onSuccess(v);
                    it.onComplete();
                }
            });
        }).subscribeOn(Schedulers.from(executorService));
    }

    /**
     * NOTICE We didn't close producer now for hivemq-plugin,
     * because kafka producer should work until end of plugin?
     */
    public void close() {
        producer.close();
    }
}
