#!/usr/bin/env python3

""" device-logs-to-elasticsearch """

from gzip import GzipFile
from io import BytesIO

import json
import os
import re
import urllib.parse

from botocore.exceptions import ClientError, WaiterError
from elasticsearch import Elasticsearch
from elasticsearch.helpers import bulk, BulkIndexError

import boto3

ES_DOMAIN_URL = os.environ['ES_DOMAIN_URL']  # the Amazon ES domain with scheme
ES_HOST = '{}:443'.format(ES_DOMAIN_URL)
INDEX_BASE = os.environ['ES_INDEX']         # 'lambda-s3-index'
INDEX_TYPE = '_doc'

MAX_RETRIES = 20
RETRY_DELAY = 3


# TODO: Turn into a regex with fallthrough?
def parse_custom_flosense_event(msg):
    """Parse flosense log events"""
    if 'flosense.py' in msg:
        flosense_event = msg.split(' ', 3)
        msg = {
            'level': flosense_event[0],
            'method_name': flosense_event[1],
            'source_file': flosense_event[2],
            'message': json.loads(flosense_event[3])
        }
    return msg


def parse_event(event_record):
    """Parse AWS S3 event and return bucket name and key."""
    message = json.loads(event_record['Sns']['Message'])
    sub_event = message['Records'][0]
    bucket = sub_event['s3']['bucket']['name']
    s3_key = sub_event['s3']['object']['key']
    s3_key = urllib.parse.unquote(s3_key)
    return bucket, s3_key


def parse_path(s3_key):
    """Parse Parquet formatted path and extract what we need."""
    path = s3_key.split('/')
    year = path[1].replace('year=', '')
    month = path[2].replace('month=', '')
    day = path[3].replace('day=', '')
    device = path[4].replace('device=', '')
    return year, month, day, device


def parse_log_line(log_line, device_id):
    """Parse log line, extract message"""
    parsed = {}
    rgx = re.compile(r'(?P<timestamp>^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\.\d+(\+\d{4}|Z)) '
                    r'(?P<hostname>flo\-(?P<device_id>\w+))* *(?P<version>[0-9a-z\.\-]*) '
                    r'(?P<process>[^ \t\n\r\f\v\[\]]+)'
                    r'\[?(?P<pid>\d+)?\]?: '
                    r'(?P<message>.*)')
    try:
        parsed = rgx.match(log_line).groupdict()
        msg = parse_custom_flosense_event(parsed['message'])
        parsed['message'] = msg
        print(msg)
        if not isinstance(msg, dict):
            raise TypeError('No Flosense Data')
    except AttributeError as err:
        print('AttributeError: {}'.format(err))
        print(log_line)
    except TypeError as err:
        print('{}\nmessage: {}'.format(err, log_line))
        msg = parsed['message']
        parsed['message'] = {'unprocessed': msg}
    return parsed


def s3_get_device_log(bucket, s3_key):
    """Retrieve device log from S3 and decompress"""
    try:
        s3 = boto3.client('s3')
        waiter = s3.get_waiter('object_exists')
        print('Waiting on object {} to be present'.format(s3_key))
        waiter.wait(
            Bucket=bucket,
            Key=s3_key,
            WaiterConfig={'Delay': RETRY_DELAY, 'MaxAttempts': MAX_RETRIES}
        )
        obj = s3.get_object(Bucket=bucket, Key=s3_key)
        byte_stream = BytesIO(obj['Body'].read())
        body = GzipFile(None, 'rb', fileobj=byte_stream).read().decode('utf-8')
        lines = body.splitlines()
    except ClientError as err:
        if err.response['Error']['Code'] == 'NoSuchKey':
            print(err)
            print('\tOn S3 object: s3:{}/{}'.format(bucket, s3_key))
        else:
            raise
    except WaiterError as err:
        if 'Max attempts exceeded' in err.message:
            print(err)
            print('Exceeded {} retry attempts'.format(MAX_RETRIES))
        else:
            raise
    return lines


def handler(event, context):
    es = Elasticsearch(ES_HOST, use_ssl=True)
    for record in event['Records']:
        bulk_event = []
        try:
            bucket, s3_key = parse_event(record)
        except Exception as err:
            print(err)
            print('Event: {}'.format(event))
            raise
        year, month, day, device = parse_path(s3_key)

        index = '{}-{}.{}.{}'.format(INDEX_BASE, year, month, day)

        try:
            lines = s3_get_device_log(bucket, s3_key)
        except Exception as err:
            print(err)
            print('Event: {}'.format(event))
            raise

        # Match the regular expressions to each line and index the JSON
        for line in lines:
            # print(line)
            document = parse_log_line(line, device)
            document['raw'] = line
            document['source'] = 's3'
            document['s3'] = {'bucket': bucket, 'path': s3_key}
            bulk_head = {
                '_index': index,
                '_type': INDEX_TYPE,
            }

            bulk_event.append(dict(**bulk_head, **document))
        try:
            bulk(es, bulk_event)
        except BulkIndexError as err:
            print(err)
            print('Event: {}'.format(event))
            raise
