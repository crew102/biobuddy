import boto3
import os
import fnmatch

client = boto3.client("logs")


def _get_all_log_groups():
    log_groups = []
    paginator = client.get_paginator("describe_log_groups")
    for page in paginator.paginate():
        log_groups.extend(page["logGroups"])
    return [group["logGroupName"] for group in log_groups]


def _get_all_log_streams(log_group_name):
    log_streams = []
    paginator = client.get_paginator("describe_log_streams")
    for page in paginator.paginate(logGroupName=log_group_name):
        log_streams.extend(page["logStreams"])
    return [stream["logStreamName"] for stream in log_streams]


def get_log_events(log_group_name, log_stream_name):
    events = []
    kwargs = {
        "logGroupName": log_group_name,
        "logStreamName": log_stream_name,
        "startFromHead": True
    }
    while True:
        response = client.get_log_events(**kwargs)
        events.extend(response["events"])
        next_token = response.get("nextForwardToken")
        if next_token and next_token != kwargs.get("nextToken"):
            kwargs["nextToken"] = next_token
        else:
            break
    return events


def _save_logs_to_file(log_group_name, log_stream_name, events):
    os.makedirs("logs", exist_ok=True)
    safe_log_stream_name = log_stream_name.replace("/", "_")
    file_path = os.path.join("logs", f"{safe_log_stream_name}.log")
    with open(file_path, "w", encoding="utf-8") as f:
        for event in events:
            timestamp = event["timestamp"]
            message = event["message"]
            f.write(f"{timestamp}\t{message}\n")


def _download_all_logs(pattern):
    log_groups = _get_all_log_groups()
    for log_group in log_groups:
        if fnmatch.fnmatch(log_group, pattern):
            print(f"Processing log group: {log_group}")
            log_streams = _get_all_log_streams(log_group)
            for log_stream in log_streams:
                print(f"  Processing log stream: {log_stream}")
                events = get_log_events(log_group, log_stream)
                _save_logs_to_file(log_group, log_stream, events)


# if __name__ == '__main__':
pattern = "*spotinterruption*"
_download_all_logs(pattern)
    # print("All logs have been downloaded successfully.")
