Runs an [Exhibitor](https://github.com/Netflix/exhibitor)-managed [ZooKeeper](http://zookeeper.apache.org/) cluster using S3 for backups and automatic node discovery.

### Usage

###### Build docker image and push it into repository
```
docker build -t <tag> .
```

###### Create the Security group
```
GROUP_ID=$(aws ec2 create-security-group --group-name app-exhibitor --description "Exhibitor security group" \
  | sed -rn 's/.*GroupId": "(.*)".*/\1/p' | tail -n 1)
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 2181 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 2888 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 3888 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 8181 --cidr 0.0.0.0/0
```

###### Create S3 bucket
```
S3_BUCKET="exhibitor-app"
aws s3 mb s3://$S3_BUCKET
```

###### Register appliance in YourTourn
Docs: http://docs.stups.io/en/latest/components/yourturn.html

###### Deploy with Senza
```
senza create exhibitor-appliance.yaml <STACK_VERSION> <DOCKER_IMAGE> $GROUP_ID <HOSTED_ZONE> $S3_BUCKET <MINT_BUCKET> <SCALYR_KEY>
```

Cloudformation stack will start 3 EC2 instances in autoscaling group and create internal load balancer in front of EC2 instances. Also it will create DNS record ```"<STACK_VERSION>.exhibitor.<HOSTED_ZONE>"``` which points to a load balancer.

Exhibitor provides [rest-api](https://github.com/Netflix/exhibitor/wiki/REST-Introduction) which could be accessd via: ```http://<STACK_VERSION>.exhibitor.<HOSTED_ZONE>/exhibitor/v1/```
