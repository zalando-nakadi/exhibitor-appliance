#/bin/bash -e

HOSTNAME=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/hostname || echo "localhost")
AVAILABILITY_ZONE=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "")

# Generates the default exhibitor config and launches exhibitor
cat /opt/exhibitor/exhibitor.conf.tmpl > exhibitor.conf
echo "backup-extra=throttle\=&bucket-name\=${S3_BUCKET}&key-prefix\=${S3_PREFIX}&max-retries\=4&retry-sleep-ms\=30000" >> exhibitor.conf

if [[ -n ${ZK_PASSWORD} ]]; then
    SECURITY="--security /opt/exhibitor/web.xml --realm Zookeeper:realm --remoteauth basic:zk"
    echo "zk: ${ZK_PASSWORD},zk" > realm
fi

if [[ $AVAILABILITY_ZONE == '' ]]; then
    echo "local environment, starting without S3 backup"
    CONFIG_TYPE="file"
else
    AWS_REGION=${AVAILABILITY_ZONE:0:${#AVAILABILITY_ZONE} - 1}
    CONFIG_TYPE="s3  --s3config ${S3_BUCKET}:${S3_PREFIX} --s3region ${AWS_REGION} --s3backup true"
fi 

# send zookeeper log to stdout
(
    ZK_LOG=zookeeper.out
    while true; do
        [[ -f $ZK_LOG ]] && tailf $ZK_LOG
        sleep 1
    done
) &

exec 2>&1

java -jar /opt/exhibitor/exhibitor.jar \
  --port 8181 --defaultconfig exhibitor.conf \
  --configtype $CONFIG_TYPE \
  --hostname ${HOSTNAME} \
  ${SECURITY}
