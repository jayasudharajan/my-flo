package com.flotechnologies.model;

import com.hivemq.spi.topic.MqttTopicPermission;

import java.util.Objects;

/**
 * Implement equals() and hashCode() for make it equalable and optimization by Sparse Matric
 */
public class SimpleMqttTopicPermission extends MqttTopicPermission {
    public SimpleMqttTopicPermission(final String topic, final TYPE type) {
        super(topic, type);
    }

    public SimpleMqttTopicPermission(final String topic, final TYPE type, final ACTIVITY activity) {
        super(topic, type, activity);
    }

    public SimpleMqttTopicPermission(final String topic, final TYPE type, final QOS qos) {
        super(topic, type, qos);
    }

    public SimpleMqttTopicPermission(final String topic, final TYPE type, final QOS qos, final ACTIVITY activity) {
        super(topic, type, qos, activity);
    }

    public SimpleMqttTopicPermission(final String topic, final TYPE type, final QOS qos, final ACTIVITY activity, final RETAIN publishRetain) {
        super(topic, type, qos, activity, publishRetain);
    }

    @Override
    public boolean equals(Object o) {
        if (o == this) {
            return true;
        }
        if (o instanceof SimpleMqttTopicPermission) {
            SimpleMqttTopicPermission that = (SimpleMqttTopicPermission) o;
            return (this.getTopic().equals(that.getTopic()))
                    && (this.getType().equals(that.getType()))
                    && (this.getQos().equals(that.getQos()))
                    && (this.getActivity().equals(that.getActivity()));
        }
        return false;
    }

    @Override
    public int hashCode() {
        return Objects.hash(getTopic(), getType(), getQos(), getActivity());
    }
}
