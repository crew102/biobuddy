"""Opens up ports to dev services, needed for cases where GH Action triggered
deployment and local IP address wasn't available at infra build time."""
import os
import re

import boto3


def main():

    session = boto3.Session(region_name="us-east-1")
    ec2_client = session.client("ec2")
    response = ec2_client.describe_security_groups()

    bb_sec_groups = [
        sg for sg in response["SecurityGroups"]
        if re.search("ec2-spot", sg["GroupName"])
    ]

    ip = os.environ.get("LOCAL_IP")
    ports = [22, 9443, 8787, 3838]
    for port in ports:
        for sg in bb_sec_groups:
            try:
                ec2_client.authorize_security_group_ingress(
                    GroupId=sg["GroupId"],
                    IpPermissions=[
                        {
                            "IpProtocol": "tcp",
                            "FromPort": port,
                            "ToPort": port,
                            "IpRanges": [{"CidrIp": ip}]
                        }
                    ]
                )
                print(
                    f"Ingress rule added successfully to Security "
                    f"Group: {sg['GroupName']}"
                )
            except Exception as e:
                print(
                    f"Failed to add ingress rule to Security "
                    f"Group: {sg['GroupName']}. Error: {e}"
                )


if __name__ == "__main__":
    main()
