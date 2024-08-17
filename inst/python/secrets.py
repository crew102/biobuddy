import boto3


def get_secret(secret_name):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    ss = response["SecretString"]
    a_dict = json.loads(ss)
    return a_dict[secret_name]
