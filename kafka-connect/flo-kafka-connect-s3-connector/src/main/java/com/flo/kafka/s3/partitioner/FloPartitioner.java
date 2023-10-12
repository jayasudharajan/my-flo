/*
 * Copyright 2017 Confluent Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */

// Copyright 2018 Flo Technologies, All Rights Reserved
// Created 7/23/18 jcs

// Creates partitions using the connect-s3-sink.properties:
//   partition.field.timestamp defines the field which is the 64-bit UTC timestamp.
//   partition.field.name defines the fields which will be used to construct the partition format.
//   partition.field.name=did,ts
//   path.format = yyyy/MM/dd
// The output on S3 is constructed as follows, where 'did' is the device id, and 'ts' is a 64-bit timestamp converted into
// the date-time format as specified by path.format. Example output on S3:
//   topics/flo-telemetry/f87aef0100ce/2018/06/29/flo-telemetry+0+0000000078.avro
// If partition.field.name=ts,did, the date would be ordered first, followed by the device id.

package com.flo.kafka.s3.partitioner;

import io.confluent.connect.storage.common.StorageCommonConfig;
import io.confluent.connect.storage.errors.PartitionException;
import io.confluent.connect.storage.partitioner.DefaultPartitioner;

import io.confluent.connect.storage.partitioner.PartitionerConfig;
import org.apache.kafka.common.utils.Utils;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.Schema.Type;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.sink.SinkRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;

import static org.apache.kafka.connect.data.Schema.Type.INT64;

public class FloPartitioner<T> extends DefaultPartitioner<T> {
  private static final Logger log = LoggerFactory.getLogger(FloPartitioner.class);
  private static final String SCHEMA_GENERATOR_CLASS = "io.confluent.connect.storage.hive.schema.TimeBasedSchemaGenerator";
  private List<String> fieldNames;
  private String dateFormat = "yyyy/MM/dd";   // Default
  private String timeStampField = "ts";       // Default

  public static final String PARTITION_FIELD_TIMESTAMP = "partition.field.timestamp";

  public FloPartitioner() {
  }

  @Override
  public void configure(Map<String, Object> config) {
    fieldNames = (List<String>) config.get(PartitionerConfig.PARTITION_FIELD_NAME_CONFIG);
    delim = (String) config.get(StorageCommonConfig.DIRECTORY_DELIM_CONFIG);

    String timeStampFieldConfig = (String) config.get(PARTITION_FIELD_TIMESTAMP);
    if (timeStampFieldConfig != null && !timeStampFieldConfig.isEmpty()) {
      timeStampField = timeStampFieldConfig;
    }

    String dateFormatConfig = (String) config.get(PartitionerConfig.PATH_FORMAT_CONFIG);
    if (dateFormatConfig != null && !dateFormatConfig.isEmpty()) {
      dateFormat = dateFormatConfig;
    }
  }

  public String encodePartition(SinkRecord sinkRecord) {
    Object value = sinkRecord.value();
    if (value instanceof Struct) {
      final Schema valueSchema = sinkRecord.valueSchema();
      final Struct struct = (Struct) value;
      
      StringBuilder builder = new StringBuilder();
      for (String fieldName : fieldNames) {
        
        if (builder.length() > 0) {
          builder.append(this.delim);
        }
        
        Object partitionKey = struct.get(fieldName);
        Type type = valueSchema.field(fieldName).schema().type();

        if (fieldName.equals(timeStampField)) {
          if (type == INT64) {
            Number record = (Number) partitionKey;
            SimpleDateFormat simpleDateFormat = new SimpleDateFormat(dateFormat);
            String dateTime = simpleDateFormat.format(record);
            builder.append(dateTime);
          } else {
            log.error("For {}={}, Type {} is not supported as a partition timestamp key: must be 64-bit.", PARTITION_FIELD_TIMESTAMP, timeStampField, type.getName());
            throw new PartitionException("Error encoding partition.");
          }
        } else {
          switch (type) {
            case INT8:
            case INT16:
            case INT32:
            case INT64:
              Number record = (Number) partitionKey;
              builder.append(record.toString());
              break;
            case STRING: // The device id string
              builder.append((String) partitionKey);
              break;
            case BOOLEAN:
              boolean booleanRecord = (boolean) partitionKey;
              builder.append(Boolean.toString(booleanRecord));
              break;
            default:
              log.error("Type {} is not supported as a partition key.", type.getName());
              throw new PartitionException("Error encoding partition.");
          }
        }
      }
      return builder.toString();
    } else {
      log.error("Value is not Struct type.");
      throw new PartitionException("Error encoding partition.");
    }
  }

  @Override
  public List<T> partitionFields() {
    if (partitionFields == null) {
      partitionFields = newSchemaGenerator(config).newPartitionFields(Utils.join(fieldNames,","));
    }
    return partitionFields;
  }

}
