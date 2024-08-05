import aws_cdk as cdk
from ec2.ec2_spot import EC2spot

app = cdk.App()

EC2spot(
    app, "ec2-spot-staging",
    environment="staging",
    allocation_id="eipalloc-023ea7cfc4367442b"
)

EC2spot(
    app, "ec2-spot-prod",
    environment="prod",
    allocation_id="eipalloc-036052c2719eb7748"
)

app.synth()
