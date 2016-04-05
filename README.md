Runs an [Exhibitor](https://github.com/Netflix/exhibitor)-managed [ZooKeeper](http://zookeeper.apache.org/) cluster using S3 for backups and automatic node discovery.

### Usage

###### Build docker image and push it into repository
```
docker build -t <tag> .
```

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
senza create exhibitor-appliance.yaml <STACK_VERSION> <APPLICATION_ID> <DOCKER_IMAGE_WITH_VERSION_TAG> <HOSTED_ZONE> $S3_BUCKET <MINT_BUCKET> <SCALYR_KEY> [--region AWS_REGION]
```

A real world example would be:
	senza create exhibitor-appliance.yaml 1 \
	ApplicationId=acid-exhibitor \
	DockerImage=pierone.example.org/myteam/exhibitor:0.1-SNAPSHOT \
	HostedZone=example.org. \
	ExhibitorBucket=exhibitor-bucket \
	MintBucket=example-stups-mint-some_id-eu-west-1 \
	ScalyrAccountKey=some_scalyr_key \
	--region eu-west-1

Cloudformation stack will start 3 EC2 instances in autoscaling group and create internal load balancer in front of EC2 instances. Also it will create DNS record ```"<APPLICATION_ID>-<STACK_VERSION>.<HOSTED_ZONE>"``` which points to a load balancer.

Exhibitor provides [rest-api](https://github.com/Netflix/exhibitor/wiki/REST-Introduction) which could be accessd via: ```http://<APPLICATION_ID>-<STACK_VERSION>.<HOSTED_ZONE>/exhibitor/v1/```

###### Access

The provided Yaml file creates only a internal LoadBalancer. For security reasons you should not expose freely the exhibitor interface, since it has by default not authorization. For access you should look into this script: https://github.com/zalando-stups/ssh-tunnels

