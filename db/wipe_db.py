from inst.python.s3 import delete_s3_path, get_catchall_bucket_name

bucket = get_catchall_bucket_name()
delete_s3_path(bucket, "db/rewrites.csv")
delete_s3_path(bucket, "db/run-exit-status.csv")
delete_s3_path(bucket, "db/seen-on.csv")
delete_s3_path(bucket, "db/img")
