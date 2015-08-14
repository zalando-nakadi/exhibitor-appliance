#/bin/bash -e

HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
AVAILABILITY_ZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
AWS_REGION=${AVAILABILITY_ZONE:0:${#AVAILABILITY_ZONE} - 1}

# Generates the default exhibitor config and launches exhibitor
cat /opt/exhibitor/exhibitor.conf.tmpl > exhibitor.conf
echo "backup-extra=throttle\=&bucket-name\=${S3_BUCKET}&key-prefix\=${S3_PREFIX}&max-retries\=4&retry-sleep-ms\=30000" >> exhibitor.conf

if [[ -n ${ZK_PASSWORD} ]]; then
    SECURITY="--security /opt/exhibitor/web.xml --realm Zookeeper:realm --remoteauth basic:zk"
    echo "zk: ${ZK_PASSWORD},zk" > realm
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
  --configtype s3 --s3config ${S3_BUCKET}:${S3_PREFIX} \
  --s3region ${AWS_REGION} --s3backup true \
  --hostname ${HOSTNAME} \
  ${SECURITY}
