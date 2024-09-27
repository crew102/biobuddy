import aws_cdk as cdk

from bbstack import BiobuddyStack

app = cdk.App()

BiobuddyStack(
    app, "bb-app-staging",
    environment="staging",
    allocation_id="eipalloc-023ea7cfc4367442b"
)
BiobuddyStack(
    app, "bb-app-prod",
    environment="prod",
    allocation_id="eipalloc-036052c2719eb7748"
)
BiobuddyStack(
    app, "bb-app-prod-restart",
    environment="prod",
    restart=True,
    allocation_id="eipalloc-036052c2719eb7748"
)

app.synth()
