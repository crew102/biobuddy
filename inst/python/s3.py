import os
import json
import logging
from datetime import datetime

import boto3

S3_CLIENT = boto3.client("s3")
logger = logging.getLogger()


def get_catchall_bucket_name():
    response = S3_CLIENT.list_buckets()
    bucks = [
        bucket["Name"] for bucket in response["Buckets"]
        if "ec2-spot-catchall" in bucket["Name"]
    ]
    if len(bucks) != 1:
        RuntimeError("No catchall bucket found")
    return bucks[0]


def download_file_from_s3(bucket_name, remote_path, local_path):
    S3_CLIENT.download_file(bucket_name, remote_path, local_path)
    logger.info(f"Downloaded {remote_path} to {local_path}")


def upload_file_to_s3(bucket_name, remote_path, local_path):
    S3_CLIENT.upload_file(local_path, bucket_name, remote_path)
    logger.info(f"Uploaded {local_path} to s3://{bucket_name}/{remote_path}")


def download_dir_from_s3(bucket_name, remote_dir, local_dir):
    if not os.path.exists(local_dir):
        os.makedirs(local_dir)

    response = S3_CLIENT.list_objects_v2(Bucket=bucket_name, Prefix=remote_dir)

    if "Contents" in response:
        for obj in response["Contents"]:
            remote_path = obj["Key"]
            file_name = os.path.basename(remote_path)
            local_path = os.path.join(local_dir, file_name)

            S3_CLIENT.download_file(bucket_name, remote_path, local_path)
            logger.info(f"Downloaded {remote_path} to {local_path}")
    else:
        logger.info(f"No files found in {remote_dir}")


def upload_dir_to_s3(bucket_name, remote_dir, local_dir):
    for root, dirs, files in os.walk(local_dir):
        for file in files:
            local_path = os.path.join(root, file)
            relative_path = os.path.relpath(local_path, local_dir)
            s3_key = os.path.join(remote_dir, relative_path).replace("\\", "/")

            S3_CLIENT.upload_file(local_path, bucket_name, s3_key)
            logger.info(f"Uploaded {local_path} to s3://{bucket_name}/{s3_key}")


def list_files_in_s3(bucket_name, remote_dir):
    file_list = []

    response = S3_CLIENT.list_objects_v2(Bucket=bucket_name, Prefix=remote_dir)

    if "Contents" in response:
        for obj in response["Contents"]:
            file_list.append(obj["Key"])

    return file_list


def delete_s3_path(bucket_name, remote_dir):
    response = S3_CLIENT.list_objects_v2(
        Bucket=bucket_name, Prefix=remote_dir
    )

    if "Contents" in response:
        for obj in response["Contents"]:
            S3_CLIENT.delete_object(Bucket=bucket_name, Key=obj["Key"])
            print(f"Deleted {obj['Key']}")


def backup_s3_bucket(source_bucket_name, backup_bucket_prefix):
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    backup_bucket_name = f"{backup_bucket_prefix}-{timestamp}"

    S3_CLIENT.create_bucket(Bucket=backup_bucket_name)
    logger.info(f"Created backup bucket: {backup_bucket_name}")

    copy_source = {"Bucket": source_bucket_name}
    response = S3_CLIENT.list_objects_v2(Bucket=source_bucket_name)
    if "Contents" in response:
        for obj in response["Contents"]:
            copy_source["Key"] = obj["Key"]
            S3_CLIENT.copy_object(
                CopySource=copy_source,
                Bucket=backup_bucket_name,
                Key=obj["Key"]
            )
            logger.info(f"Copied {obj['Key']} to {backup_bucket_name}")

    return backup_bucket_name


def delete_old_catchall_buckets():
    response = S3_CLIENT.list_buckets()
    for bucket in response["Buckets"]:
        bucket_name = bucket["Name"]
        # TODO: HANDLE DEV/PROD DATA DISTINCTION
        if "ec2-spot-catchall-DEV" in bucket_name:
            creation_date = bucket["CreationDate"].replace(tzinfo=None)
            age = datetime.now() - creation_date
            if age.days > 5:
                S3_CLIENT.delete_bucket(Bucket=bucket_name)
                logger.info(f"Deleted bucket: {bucket_name}")


def make_imgs_readable(bucket_name):
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": f"arn:aws:s3:::{bucket_name}/app/db/img/*",
            }
        ],
    }
    policy_json = json.dumps(policy)
    S3_CLIENT.put_bucket_policy(Bucket=bucket_name, Policy=policy_json)
