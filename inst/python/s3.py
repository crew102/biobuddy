import os
import json

import boto3

S3_CLIENT = boto3.client("s3")


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
    print(f"Downloaded {remote_path} to {local_path}")


def upload_file_to_s3(bucket_name, remote_path, local_path):
    S3_CLIENT.upload_file(local_path, bucket_name, remote_path)
    print(f"Uploaded {local_path} to s3://{bucket_name}/{remote_path}")


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
            print(f"Downloaded {remote_path} to {local_path}")
    else:
        print(f"No files found in {remote_dir}")


def upload_dir_to_s3(bucket_name, remote_dir, local_dir):                        
    for root, dirs, files in os.walk(local_dir):                                  
        for file in files:                                                        
            local_path = os.path.join(root, file)                                 
            relative_path = os.path.relpath(local_path, local_dir)                
            s3_key = os.path.join(remote_dir, relative_path).replace("\\", "/")  
                                                                                  
            S3_CLIENT.upload_file(local_path, bucket_name, s3_key)                
            print(f"Uploaded {local_path} to s3://{bucket_name}/{s3_key}")
            

def make_imgs_readable(bucket_name):
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": f"arn:aws:s3:::{bucket_name}/db/img/*",
            }
        ],
    }
    policy_json = json.dumps(policy)
    S3_CLIENT.put_bucket_policy(Bucket=bucket_name, Policy=policy_json)
