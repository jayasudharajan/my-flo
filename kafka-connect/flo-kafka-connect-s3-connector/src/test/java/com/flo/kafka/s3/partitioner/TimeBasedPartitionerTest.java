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

package com.flo.kafka.s3.partitioner;

import io.confluent.connect.storage.StorageSinkTestBase;
import io.confluent.connect.storage.common.StorageCommonConfig;
import io.confluent.connect.storage.partitioner.PartitionerConfig;
import org.apache.commons.lang.math.NumberRange;
import org.apache.kafka.common.record.TimestampType;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.SchemaBuilder;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.sink.SinkRecord;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.junit.Test;

import java.util.*;
import java.util.concurrent.TimeUnit;

import static org.junit.Assert.assertEquals;

public class TimeBasedPartitionerTest extends StorageSinkTestBase {
  private static final String timeZoneString = "America/Los_Angeles";
  private static final DateTimeZone DATE_TIME_ZONE = DateTimeZone.forID(timeZoneString);
  private static final String DEVICE_ID_FIELD = "did";
  private static final String TIMESTAMP_FIELD = "ts";
  private static final String DATE_PATH_FORMAT = "yyyy/MM/dd";

  private static final String DEVICE_ID = "xyz123";
  private static final String DEVICE_ID_DEFAULT = "0";
  private static final Number YEAR  = 2018;
  private static final Number MONTH = 7;
  private static final Number DAY   = 24;

  @Test
  public void testFloFieldTimeExtractor() {
    FloPartitioner<String> partitioner = new FloPartitioner<>();
    List<String> fields = Arrays.asList(DEVICE_ID_FIELD, TIMESTAMP_FIELD);
    Map<String, Object> config = createFloConfig(fields);
    partitioner.configure(config);

    long timestamp = new DateTime(YEAR.intValue(), MONTH.intValue(), DAY.intValue(), 0, 0, 0, 0, DateTimeZone.forID(timeZoneString)).getMillis();
    SinkRecord sinkRecord = createRecordWith_did_ts_Fields(timestamp);

    String encodedPartition = partitioner.encodePartition(sinkRecord);

    String expectedValue = DEVICE_ID + "/" + YEAR.toString() + "/" + String.format("%02d",MONTH.intValue()) + "/" + String.format("%02d",DAY.intValue());

    assertEquals(expectedValue, encodedPartition);
  }

  private Map<String, Object> createFloConfig(List<String> fields) {
    Map<String, Object> config = new HashMap<>();

    config.put(StorageCommonConfig.DIRECTORY_DELIM_CONFIG, StorageCommonConfig.DIRECTORY_DELIM_DEFAULT);
    config.put(PartitionerConfig.PARTITION_DURATION_MS_CONFIG, TimeUnit.HOURS.toMillis(1));
    config.put(PartitionerConfig.LOCALE_CONFIG, Locale.US.toString());
    config.put(PartitionerConfig.TIMEZONE_CONFIG, DATE_TIME_ZONE.toString());

    config.put(PartitionerConfig.PARTITION_FIELD_NAME_CONFIG, fields);
    config.put(PartitionerConfig.PATH_FORMAT_CONFIG, DATE_PATH_FORMAT);
    config.put(FloPartitioner.PARTITION_FIELD_TIMESTAMP, TIMESTAMP_FIELD);

    return config;
  }

  private Schema createSchemaWith_did_ts_Fields() {
    return SchemaBuilder.struct().name("record").version(1).field("boolean", Schema.BOOLEAN_SCHEMA).field("int", Schema.INT32_SCHEMA).field("long", Schema.INT64_SCHEMA).field("float", Schema.FLOAT32_SCHEMA).field("double", Schema.FLOAT64_SCHEMA).field(DEVICE_ID_FIELD, SchemaBuilder.string().defaultValue(DEVICE_ID_DEFAULT).build()).field(TIMESTAMP_FIELD, Schema.INT64_SCHEMA).build();
  }

  private SinkRecord createRecordWith_did_ts_Fields(long timestamp) {
    Schema schema = createSchemaWith_did_ts_Fields();
    Struct record = (new Struct(schema)).put("boolean", true).put("int", 12).put("long", 12L).put("float", 12.2F).put("double", 12.2D).put(DEVICE_ID_FIELD, DEVICE_ID).put(TIMESTAMP_FIELD, timestamp);
    return new SinkRecord(TOPIC, PARTITION, Schema.STRING_SCHEMA, null, schema, record, 0L, timestamp, TimestampType.CREATE_TIME);
  }

}