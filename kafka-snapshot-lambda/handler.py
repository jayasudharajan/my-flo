import json
import boto3
import logging

from dateutil.tz import tzlocal
import datetime


def kafka_ebs_volumes():
    instances = boto3.client('ec2').describe_instances(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [
                    'dev-kafka-cherry-KafkaBrokerA',
                    'dev-kafka-cherry-KafkaBrokerB',
                    'dev-kafka-cherry-KafkaBrokerC',
                    'prod-kafka-cherry-KafkaBrokerA',
                    'prod-kafka-cherry-KafkaBrokerB',
                    'prod-kafka-cherry-KafkaBrokerC'
                ]
            },
        ],
        MaxResults=123
    )
    ebs_names = []
    for ins in [x['Instances'][0] for x in instances['Reservations']]:
        mappings = list(filter(lambda blk: "sda" not in blk["DeviceName"], ins["BlockDeviceMappings"]))
        if len(mappings) > 0:
            ebs_names.append(mappings[0]['Ebs']['VolumeId'])
        else:
            logging.error("Volume not found!")
    return ebs_names


def get_snapshots(volume_ids=[], tags=[], region='us-west-2'):
    filters = []
    if len(volume_ids) > 0:
        filters.append({
            'Name': 'volume-id',
            'Values': volume_ids
        }
        )
    for tag in tags:
        if 'Name' in tag and 'Values' in tag:
            filters.append(tag)
    return boto3.client('ec2', region_name=region).describe_snapshots(
        Filters=filters
    )['Snapshots']


def copy_snapshot(snapshot_id, source_volume_id):
    boto3.client('ec2', region_name='us-east-2').copy_snapshot(
        Description='Snapshot created by kafka-snapshot-lambda',
        SourceRegion='us-west-2',
        SourceSnapshotId=snapshot_id,
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': [
                    {
                        'Key': 'SourceVolumeId',
                        'Value': source_volume_id
                    }
                ]
            }
        ]
    )
    boto3.client('ec2').create_tags(
        Resources=[snapshot_id],
        Tags=[
            {
                'Key': 'HasCopy',
                'Value': 'True'
            }
        ]
    )


def create_snapshot(volume_id):
    boto3.client('ec2').create_snapshot(
        Description='Snapshot created by kafka-snapshot-lambda',
        VolumeId=volume_id
    )


def delete_snapshot(snapshot_id, region='us-west-2'):
    boto3.client('ec2', region_name=region).delete_snapshot(
        SnapshotId=snapshot_id
    )


def kafka_snapshot(event, context):
    ebs_volumes = kafka_ebs_volumes()
    snapshots = get_snapshots(ebs_volumes)
    # find copied snapshots and remove
    to_remove = list(filter(
        lambda snapshot:
        ("HasCopy" in [tag['Key'] for tag in snapshot.get('Tags', '')])
        or
        (datetime.datetime.now(tzlocal()) - snapshot['StartTime']).days > 2,
        snapshots
    ))
    for s in to_remove:
        delete_snapshot(s['SnapshotId'])
    tags_of_dr_snapshots = {
        'Name': 'tag:SourceVolumeId',
        'Values': []
    }
    for vol in ebs_volumes:
        tags_of_dr_snapshots['Values'].append(vol)
        create_snapshot(vol)

    # not copied
    for snapshot in list(filter(lambda snapshot: "HasCopy" not in [tag['Key'] for tag in snapshot.get('Tags', '')], snapshots)):
        copy_snapshot(snapshot['SnapshotId'], snapshot['VolumeId'])

    # remove expired snapshots in DR region
    dr_snapshots = get_snapshots([], [tags_of_dr_snapshots], 'us-east-2')
    for old_snapshot in list(filter(lambda snapshot: (datetime.datetime.now(tzlocal()) - snapshot['StartTime']).days > 2, dr_snapshots)):
        delete_snapshot(old_snapshot['SnapshotId'], 'us-east-2')

    response = {
        "statusCode": 200,
        "body": json.dumps(body)
    }

    return response

    # Use this code if you don't use the http event with the LAMBDA-PROXY
    # integration
    """
    return {
        "message": "Go Serverless v1.0! Your function executed successfully!",
        "event": event
    }
    """
