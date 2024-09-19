`gh workflow run run-tests.yml -f logLevel=warning -f tags=false -f environment=staging`

export APP_IMAGE=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep bb-app)

find . -type f -print0 | xargs -0 ls -lt | head -n 15

brew install cmake

dlib
opencv-python 


sudo du -sh */ | sort -hr
 
[//]: # (iss = ec2.describe_instances&#40;&#41;)
[//]: # (iss['Reservations'][0]['Instances'][0]['InstanceId'])

https://docs.docker.com/reference/cli/docker/builder/prune/

sudo docker builder prune
 
* reminder: i had to set the number of hops in the default settings for ec2 instances (related to metadata options)

for startup logs on ec2:

`/var/log/cloud-init.log`
`/var/log/cloud-init-output.log`

------- CHANGE METADATA STUFF
To set IMDSv2 as the default for the account for the specified Region

Open the Amazon EC2 console at https://console.aws.amazon.com/ec2/.
To change the AWS Region, use the Region selector in the upper-right corner of the page.
In the navigation pane, choose EC2 Dashboard.
Under Account attributes, choose Data protection and security.
Next to IMDS defaults, choose Manage.
On the Manage IMDS defaults page, do the following:
For Instance metadata service, choose Enabled.
For Metadata version, choose V2 only (token required).
For Metadata response hop limit, specify 2 if your instances will host containers. Otherwise, select No preference. When no preference is specified, at launch, the value defaults to 2 if the AMI requires IMDSv2; otherwise it defaults to 1.
Choose Update.

-----------


sudo chmod -R 777 biobuddy/

metadata_options_property = ec2.CfnLaunchTemplate.MetadataOptionsProperty(
    http_endpoint="httpEndpoint",
    http_protocol_ipv6="httpProtocolIpv6",
    http_put_response_hop_limit=123,
    http_tokens="httpTokens",
    instance_metadata_tags="instanceMetadataTags"
)
--metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required","InstanceMetadataTags":"enabled"}'

---------


```aws ec2 describe-instances --instance-ids i-0eb6294dcbaf253b1 --query 'Reservations[*].Instances[*].LaunchTime' --output text```


```
aws ec2 describe-images --output json --region us-east-2 --filters "Name=name,Values=ubuntu/images/*" > temp.json

library(jsonlite)
library(tibble)
library(dplyr)
fromJSON('temp.json') -> k
k$Images %>% as_tibble() %>% View
```

https://docs.docker.com/engine/install/ubuntu/

ssh -i "pair-2.pem" ubuntu@biobuddydev.com



------ github access within ec2

store ssh token as aws secret

at image build i will have to take that secret and write to the file below, then

chmod 600 ~/.ssh/id_rsa

then i can do `git clone git@github.com:crew102/wosr.git`

--------

echo $CR_PAT | docker login ghcr.io -u crew102 --password-stdin
docker tag bb-app:latest ghcr.io/crew102/bb-app:latest
docker push ghcr.io/crew102/bb-app:latest

## push image to github packages repo (having saved PAT to CR_PAT envvar)

echo $CR_PAT | docker login ghcr.io -u crew102 --password-stdin
docker tag bb-app:v0.0.9 ghcr.io/crew102/bb-app:v0.0.9
docker push ghcr.io/crew102/bb-app:latest


--- existing image, no special tags, add tag:
docker tag d20dbc7090dc bb-app:v0.0.9

--
docker tag bb-app:v0.0.9 ghcr.io/crew102/bb-app:v0.0.9

-- then push to repo as `docker push ghcr.io/crew102/bb-app:v0.0.9`


## spin up down strategy

spot instance with backup "on demand instance"
  on demand is normally powereed down
  "cloudwatch" event triggers "lambda" function when spot needs to be terminated
  lambda function associates elastic ip with on demand instance and starts it up

final piece:
  Application Load Balancer (ALB)
  ALB: Use an Application Load Balancer to route traffic to the Spot Instance and failover to the On-Demand Instance if the Spot Instance is terminated.
  Health Checks: Configure health checks to ensure the ALB routes traffic to the healthy instance.

*moved id_rsa private key to server from laptop so i can talk to github&*

chmod 400 ~/.ssh/id_rsa 

git clone git@github.com:crew102/biobuddy.git

mv  biobuddy/ ~/

~/.config/rstudio/rstudio-prefs.json

updated firebase to allow domain that is the elastic ip addres s ihave

## domain and cert

create domain on s3, validate email address
      
CNAME record

A Canonical Name (CNAME) record is a type of resource record in the Domain Name System (DNS) that maps one domain name (an alias) to another (the canonical ...



ADD "A" RECORD 
Add an A Record:

Click on your hosted zone to view its records.
Click “Create record”.
Choose “Simple routing”.
Enter the following details:
Record name: Leave it blank to use the root domain or enter www for www.yourdomain.com.
Record type: Select A – IPv4 address.
Value: Enter the public IP address of your EC2 instance.
TTL (Time to Live): Leave it at the default (300 seconds) or set as desired.
Click “Create records”.


`ping biobuddydev.com` to verify going to correct ip address


instructions to get cert from inside nginx container: 

> Certbot is a free, open-source tool that automates the process of *obtaining* and renewing SSL/TLS certificates from Let's Encrypt, a Certificate Authority (CA) that provides free SSL/TLS certificates. Here's an overview of both Certbot and Let's Encrypt and how they are related:

> Certbot is a client developed by the Electronic Frontier Foundation (EFF) to interact with the Let's Encrypt CA.


----------

# secrets management in aws


Sure! Here are the detailed steps to create an IAM role with permissions to access AWS Secrets Manager and attach it to your EC2 instance:

Create an IAM Role
Go to the IAM Console:

Open the AWS Management Console.
Navigate to the IAM service.
Create a New Role:

In the IAM Dashboard, click on "Roles" in the left sidebar.
Click the "Create role" button.
Select a Trusted Entity:

Choose the "AWS service" option.
Select "EC2" from the list of services.
Click "Next: Permissions".
Attach Policies:

Search for and select the policy SecretsManagerReadWrite to give the EC2 instance permissions to access Secrets Manager. If you want more fine-grained control, you can create a custom policy.
Click "Next: Tags". (Adding tags is optional)
Click "Next: Review".
Review and Create the Role:

Provide a name for the role, such as EC2SecretsManagerRole.
Add an optional description.
Click "Create role".
Attach the IAM Role to Your EC2 Instance
Go to the EC2 Console:

Open the EC2 Management Console.
Select Your EC2 Instance:

In the EC2 Dashboard, click on "Instances" in the left sidebar.
Select the instance you want to attach the IAM role to.
Attach the IAM Role:

With your instance selected, click on the "Actions" dropdown menu.
Navigate to "Security" and select "Modify IAM role".
Modify IAM Role:

In the "Modify IAM role" dialog, select the role you created earlier (EC2SecretsManagerRole) from the dropdown.
Click "Update IAM role".
Verify the Role Attachment
Verify the Role in the Instance Description:
Go back to the EC2 Dashboard.
Select your instance and look at the "Description" tab.
You should see the IAM role listed under "IAM role".





####
 if you need to create an adhoc ebs volume and mount into an existing ec2 container:
 
 

lsblk


sudo mkfs -t ext4 /dev/xvdf
sudo mkdir /mnt/mydata

sudo mount /dev/xvdf /mnt/mydata
sudo nano /etc/fstab

Add the following line to the file:
/dev/xvdf /mnt/mydata ext4 defaults,nofail 0 2


--- now symlink:

sudo mkdir -p /data
sudo ln -s /mnt/mydata /data

--- now update docker config:
nano of 
/etc/docker/daemon.json

{
"data-root": "/mnt/newlocation"
}

sudo systemctl restart docker





-- have to first build bb-app image so shiny proxy can launch

  R won't be installed on host so running scripts/update renv script won't work

   hence  sudo apt install r-base-core
   The version of R recorded in the lockfile will be updated:

            [4.1.2 -> 4.3.3]
            
            


https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html

If you want to run AWS CLI commands or code inside an EC2 instance, the recommended way to get credentials is to use roles for Amazon EC2. You create an IAM role that specifies the permissions that you want to grant to applications that run on the EC2 instances. When you launch the instance, you associate the role with the instance.

Applications, AWS CLI, and Tools for Windows PowerShell commands that run on the instance can then get automatic temporary security credentials from the instance metadata. You do not have to explicitly get the temporary security credentials. The AWS SDKs, AWS CLI, and Tools for Windows PowerShell automatically get the credentials from the EC2 Instance Metadata Service (IMDS) and use them. The temporary credentials have the permissions that you define for the role that is associated with the instance.




# AWS Fargate and AWS Lambda are both serverless compute services provided by Amazon Web Services (AWS), but they cater to different use cases and have distinct characteristics. Here’s a detailed comparison of the two:

## AWS Fargate **USE THIS**

AWS Fargate is a serverless compute #####engine#### for containers. It allows you to run containers without having to manage the underlying infrastructure.

Ideal for running containerized applications, microservices, batch jobs, and long-running processes.
Suitable for applications that require control over the runtime environment and dependencies.
Deployment:

Deploy containerized applications using AWS ECS (Elastic Container Service) or AWS EKS (Elastic Kubernetes Service).

## AWS Lambda

AWS Lambda is a **serverless compute** ####service#### that runs your code **in response to events** and automatically manages the compute resources required by that code.
Use Cases:

Ideal for short-lived, event-driven functions and tasks.
Suitable for scenarios where you can break down the application logic into discrete functions triggered by events.


## CDK start jp

`npm install -g aws-cdk`

mkdir my-project
cd my-project
cdk init app --language python
source .venv/bin/activate
python -m pip install -r requirements.txt

`cdk bootstrap` after runnign `cdk synth`, being in directory with cdk.json

  Explanation
  AWS CDK v2: We ensure to use the v2 module structure.
  VPC and ECS Cluster: Creates a VPC and an ECS cluster within that VPC.
  Task Definition: Defines a Fargate task with a hello-world container.
  IAM Role for Lambda: Creates an IAM role with necessary permissions for the Lambda function.
  Lambda Function: Creates a Lambda function that starts the Fargate task using Spot Instances.
  EventBridge Rule: Creates a rule that triggers the Lambda function every day at 4 PM.
  This setup should resolve any AttributeError issues and correctly set up your Lambda function to launch an AWS Fargate Spot instance each day at 4 PM, running the hello-world Docker container.


### Bootstrapping
Bootstrapping is the process of setting up initial resources required by the CDK to deploy stacks into your AWS environment. This process creates resources that are necessary for the CDK to perform deployments, such as an S3 bucket for storing assets and IAM roles for deployment actions. This step is typically done once per environment (account/region) and includes the following actions:

Creating an S3 Bucket: This bucket is used to store assets (e.g., Lambda function code, Docker images) that are referenced in your CDK stacks.
Creating IAM Roles: These roles allow the CDK toolkit to perform actions on your behalf during deployments, such as creating and updating resources.
Setting Up Metadata: The bootstrap process might also configure some metadata that the CDK uses for deployments.

When to Bootstrap: You need to bootstrap an environment the first time you deploy a CDK stack to a new AWS account or region. If your environment is already bootstrapped, you don’t need to repeat this step unless there are changes to the bootstrap resources.

### Deploying
Deploying a stack involves taking your CDK app, which defines AWS resources using the CDK constructs, and actually creating or updating those resources in your AWS account. The deployment process includes the following steps:

Synthesis: The CDK application code is synthesized into an AWS CloudFormation template.
Asset Upload: Any assets (like Lambda code) referenced in the stack are uploaded to the bootstrap S3 bucket.
CloudFormation Stack Creation/Update: The synthesized CloudFormation template is deployed, creating or updating AWS resources as defined in your CDK app.
When to Deploy: You deploy whenever you want to create new resources or update existing resources as defined in your CDK stack. Deployment can be done multiple times as you develop and iterate on your infrastructure.

### Summary
Bootstrapping: Sets up initial required resources (like an S3 bucket and IAM roles) that the CDK needs to deploy stacks. This is a one-time setup per account/region.
Deploying: Creates or updates AWS resources as defined in your CDK app. This is done each time you want to apply changes to your infrastructure.


## boto3 vs cdk
When to Use Each
Use Boto3 when you need to interact with AWS services directly from your Python code, such as writing scripts to upload files to S3, starting/stopping EC2 instances, or any other direct AWS service interaction.
Use AWS CDK when you need to define, provision, and manage AWS infrastructure in a repeatable and maintainable way, leveraging the benefits of infrastructure as code.

https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ecs/client/run_task.html
> You can attach Amazon EBS volumes to Amazon ECS tasks by configuring the volume when creating or updating a service. For more infomation, see Amazon EBS volumes in the Amazon Elastic Container Service Developer Guide.


### pipelines cicd

npx cdk bootstrap aws://797137051954/us-east-1 --cloudformation-execution-policies arn:aws:iam::aws:policy/AdministratorAccess

Types of Capacity Provider:

Amazon ECS offers two types of Capacity Providers that you can use to manage the capacity in your ECS cluster:

Amazon ECS workloads that are hosted on Fargate:
Fargate Capacity Providers are designed for tasks that run on AWS Fargate, a serverless compute engine for containers. When you create a Fargate Capacity Provider, you specify the Fargate Spot or Fargate On-Demand launch type. Fargate Capacity Providers are ideal for workloads that require a serverless container execution environment with automatic scaling and no need to manage the underlying infrastructure.

Amazon ECS workloads that are hosted on Amazon EC2 instances:
EC2 Capacity Providers are used for tasks that run on Amazon EC2 instances. You can create EC2 Capacity Providers that are either associated with On-Demand instances or Spot instances. EC2 Capacity Providers are well-suited for workloads that require more control over the underlying EC2 instances, custom instance types, and support for different instance families.




## aws cli login

installed aws cli and ran `aws login`. i think i then was prompoted for some details, which i had found on the portal


## for aws cdk



sed -n 's/^Version: //p' DESCRIPTION

it’s possible to directly use environment variables in the value of a property, e.g. to use the variable MY_SHINYPROXY_TITLE:
proxy:
  title: ${MY_SHINYPROXY_TITLE}





## instance from scratch

laumchinstance
instance type, something reasonable
key pair add yours
select existing security group, choose IMA good one
bumpo root volume size
ADVANCED DETAIL
  iam instance profile, choose secrets
  ignore hostname type
  *Purchasing option*
    choose spot
    
*DONE*

then go to elastic ip address service, associate it with the instance you just created

# roles

A role is an IAM identity that you can create in your account that has specific permissions. An IAM role has some similarities to an IAM user. Roles and users are both AWS identities with permissions policies that determine what the identity can and cannot do in AWS. However, instead of being uniquely associated with one person, a role can be assumed by anyone who needs it. A role does not have standard long-term credentials such as a password or access keys associated with it. Instead, when you assume a role, it provides you with temporary security credentials for your role session.

You can use roles to delegate access to users, applications, or services that don't normally have access to your AWS resources.cd 
