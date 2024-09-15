import os

import inst.python.s3 as s3

FILE = "db/orgs.csv"
BACKUP = "db/orgs-back.csv"

bucket = s3.get_catchall_bucket_name()

s3.download_file_from_s3(bucket, FILE, FILE)
s3.upload_file_to_s3(bucket, BACKUP, FILE)

# Edit

s3.upload_file_to_s3(bucket, FILE, FILE)
os.unlink(FILE)
