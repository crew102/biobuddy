import argparse

import boto3

RULE_NAME = "spot-interruption-rule"


def _update_event_rule(switch_to):
    if switch_to == "aws.ec2":
        switch_from = "custom.ec2.simulation"
    else:
        switch_from = "aws.ec2"

    client = boto3.client("events")

    # Get the current rule
    response = client.describe_rule(Name=RULE_NAME)

    # Update the event pattern
    event_pattern = response["EventPattern"]
    event_pattern = event_pattern.replace(f"'{switch_from}'", f"'{switch_to}'")

    # Update the rule with the new event pattern
    client.put_rule(
        Name=RULE_NAME,
        EventPattern=event_pattern,
        State=response["State"],
        Description=response["Description"],
        RoleArn=response.get("RoleArn")
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--switch_to")
    args = parser.parse_args()
    _update_event_rule(args.switch_to)
