import boto3
import logging
import os
from datetime import timedelta, datetime


def init_lambda_client(region=None):
    try:
        if region is None:
            client = boto3.client("lambda")
        else:
            client = boto3.client("lambda", region_name=region)
    except ClientError as e:
        logging.error(e)
        return False
    return client


def init_rds_client(region=None):
    try:
        if region is None:
            client = boto3.client("rds")
        else:
            client = boto3.client("rds", region_name=region)
    except ClientError as e:
        logging.error(e)
        return False
    return client


def find_instances_snapshots(client=None, delta_minutes=timedelta(minutes=30)):
    if client is None:
        client = init_rds_client()
    result = dict()
    result['has_snapshots'] = list()
    result['no_snapshots'] = list()
    instances = client.describe_db_instances()['DBInstances']
    for ins in instances:
        snapshots = client.describe_db_snapshots(DBInstanceIdentifier=ins['DBInstanceIdentifier'])['DBSnapshots']
        if len(list(filter(lambda snp: snp['SnapshotCreateTime'] > datetime.now(snp['SnapshotCreateTime'].tzinfo) - delta_minutes, snapshots))) == 0:
            result['no_snapshots'].append(ins['DBInstanceIdentifier'])
        else:
            result['has_snapshots'].append(ins['DBInstanceIdentifier'])

    return result


def create_instance_snapshot(instance_id, client=None):
    if client is None:
        client = init_rds_client()
    snapshot_id = 'lambda-snapshot-' + instance_id + datetime.now().strftime("%Y-%m-%d-%H-%M")
    client.create_db_snapshot(
        DBSnapshotIdentifier=snapshot_id,
        DBInstanceIdentifier=instance_id,
        Tags=[
            {
                'Key': 'service',
                'Value': 'rds'
            },
            {
                'Key': 'rds_instance',
                'Value': instance_id
            }
        ]
    )


def find_active_snapshots(instance_id, client=None, delta_minutes=timedelta(minutes=30)):
    if client is None:
        client = init_rds_client()
    return list(filter(
        lambda snp: (snp['SnapshotCreateTime'] > datetime.now(snp['SnapshotCreateTime'].tzinfo) - delta_minutes)
                    and snp['Status'] == 'available',
        client.describe_db_snapshots(DBInstanceIdentifier=instance_id)['DBSnapshots']
    ))


def delete_snapshot(snapshot_it, client=None):
    if client is None:
        client = init_rds_client()
    client.delete_db_snapshot(DBSnapshotIdentifier=snapshot_it)

def move_active_snapshot(snapshot_id, snapshot_arn, source_region, target_region):
    target_region_client = init_rds_client(target_region)
    target_region_client.copy_db_snapshot(
        SourceDBSnapshotIdentifier=snapshot_arn,
        TargetDBSnapshotIdentifier=snapshot_id,
        CopyTags=True,
        SourceRegion=source_region
    )


def check_snapshot_exists_region(snapshot_id, region):
    region_client = init_rds_client(region)
    try:
        region_client.describe_db_snapshot_attributes(
            DBSnapshotIdentifier=snapshot_id
        )
        return True
    except region_client.exceptions.DBSnapshotNotFoundFault as e:
        return False


def lambda_handler(even, context):
    BASE_REGION=os.environ.get("BASE_REGION")
    BACKUP_REGION=os.environ.get("BACKUP_REGION")
    if BASE_REGION is None:
        logging.error("Base region is not specified!")
        exit(1)
    if BACKUP_REGION is None:
        logging.error("Backup region is not specified")
        exit(1)
    # iterate over instances with active snapshots and move them to backup region
    instances_by_snapshots = find_instances_snapshots()
    for ins in instances_by_snapshots['no_snapshots']:
        logging.info("Creating snapshot for instance " + ins)
        create_instance_snapshot(ins)
    snapshots_to_move = []
    snapshots_to_delete = []
    for ins in instances_by_snapshots['has_snapshots']:
        active_snapshots = find_active_snapshots(ins)
        snapshots_to_move.extend(list(
            filter(lambda snapshot: not check_snapshot_exists_region(snapshot['DBSnapshotIdentifier'], BACKUP_REGION), active_snapshots)
        ))
        snapshots_to_delete.extend(list(
            filter(lambda snapshot: check_snapshot_exists_region(snapshot['DBSnapshotIdentifier'], BASE_REGION), active_snapshots)
        ))
    for snapshot in snapshots_to_move:
        logging.info("Moving snapshot " + snapshot['DBSnapshotIdentifier'] + " from region " + BASE_REGION + " to region " + BACKUP_REGION)
        move_active_snapshot(snapshot['DBSnapshotIdentifier'], snapshot['DBSnapshotArn'], BASE_REGION, BACKUP_REGION)
    for snapshot in snapshots_to_delete:
        logging.info("Deleting snapshot " + snapshot['DBSnapshotIdentifier'])
        delete_snapshot(snapshot['DBSnapshotIdentifier'])
