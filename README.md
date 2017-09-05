Runs an [Exhibitor](https://github.com/Netflix/exhibitor)-managed [ZooKeeper](http://zookeeper.apache.org/) cluster using S3 for backups and automatic node discovery.

### Usage

###### Docker Image

We advise to use the official release in the OpenSource Registry of Zalando. You can find out the latest here ([pierone-cli](https://github.com/zalando-stups/pierone-cli) must be installed):
```
DOCKER_BASE_IMAGE="registry.opensource.zalan.do/aruha/exhibitor-appliance"
DOCKER_IMAGE_VERSION=$(pierone latest aruha exhibitor-appliance --url registry.opensource.zalan.do)"
```

If you want to build your own image see here: http://docs.stups.io/en/latest/user-guide/deployment.html#prepare-the-deployment-artifact

###### Create S3 bucket
```
S3_BUCKET="exhibitor-bucket"
aws s3 mb s3://$S3_BUCKET
```

###### Register appliance in YOUR TURN
Docs: http://docs.stups.io/en/latest/components/yourturn.html

Make sure that your got an unique ```APPLICATION_ID```

###### Deploy with Senza
```
senza create exhibitor-appliance.yaml <STACK_VERSION> \
  DockerBaseImage=$DOCKER_BASE_IMAGE \
  DockerVersion=$DOCKER_IMAGE_VERSION \
  HostedZone=<HOSTED_ZONE> \
  ExhibitorBucket=$S3_BUCKET \
  ApplicationID=<APPLICATION_ID> \
  [--region AWS_REGION]
```

A real world example would be:
```
senza create exhibitor-appliance.yaml acid-exhibitor \
  DockerBaseImage=registry.opensource.zalan.do/acid/exhibitor \
  DockerVersion=3.4-p9 \
  HostedZone=example.org. \
  ExhibitorBucket=exhibitor-bucket \
  ApplicationID=exhibitor \
  --region eu-west-1
```

Cloudformation stack will start 3 EC2 instances in autoscaling group and create internal load balancer in front of EC2 instances. Also it will create DNS record ```"<APPLICATION_ID>-<STACK_VERSION>.<HOSTED_ZONE>"``` which points to a load balancer.

Exhibitor provides [rest-api](https://github.com/soabase/exhibitor/wiki/REST-Introduction) which could be accessd via: ```http://<APPLICATION_ID>-<STACK_VERSION>.<HOSTED_ZONE>/exhibitor/v1/```

###### Access

The provided Yaml file creates only a internal LoadBalancer. For security reasons you should not expose freely the exhibitor interface, since it has by default not authorization. For access you should look into this script: https://github.com/zalando-stups/ssh-tunnels
