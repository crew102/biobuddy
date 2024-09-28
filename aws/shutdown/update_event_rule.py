import argparse

import boto3

RULE_NAME_PAT = "spotinterruptionrule"
CLIENT = boto3.client("events")


def _list_event_rules():
    paginator = CLIENT.get_paginator("list_rules")
    matching_rules = []

    for page in paginator.paginate():
        for rule in page["Rules"]:
            if RULE_NAME_PAT in rule["Name"]:
                matching_rules.append(rule["Name"])

    return matching_rules


def _update_event_rule(switch_to):
    if switch_to == "aws.ec2":
        switch_from = "custom.ec2.simulation"
    else:
        switch_from = "aws.ec2"

    client = boto3.client("events")
    rules = _list_event_rules()
    if len(rules) != 1:
        raise RuntimeError(
            "There should be just one rule related to prod spot "
            "interruption handling"
        )

    # Get the current rule
    response = CLIENT.describe_rule(Name=rules[0])

    # Update the event pattern
    event_pattern = response["EventPattern"]
    event_pattern = event_pattern.replace(f'"{switch_from}"', f'"{switch_to}"')

    # Update the rule with the new event pattern
    client.put_rule(
        Name=rules[0],
        EventPattern=event_pattern,
        State=response["State"],
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--switch_to")
    args = parser.parse_args()
    _update_event_rule(args.switch_to)
