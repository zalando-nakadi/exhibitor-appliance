#!/bin/bash
user_id=$(id -u)
sed -i "s/pwd.getpwuid(os.geteuid()).pw_name/$user_id/" /tmp/scalyr-agent-2.0.11/py/scalyr_agent/platform_posix.py
sed -i "s/pwd.getpwuid(os.stat(file_path).st_uid).pw_name/$user_id/" /tmp/scalyr-agent-2.0.11/py/scalyr_agent/platform_posix.py
scalyr-agent-2-config --set-key "$SCALYR_ACCOUNT_KEY"
IFS=',' read -a scalyr_logs <<< "$SCALYR_LOGS"
log_json=""
for log in "${scalyr_logs[@]}"
do
   log_json="$log_json{path: \""$log"\", attributes: {parser: \"standardLog\"}},"
done
log_json=${log_json::-1}
log_json=$(echo "$log_json" | sed "s/\//\\\\\//g")
sed -i "s/\/\/ { path: \"\/var\/log\/httpd\/access.log\", attributes: {parser: \"accessLog\"} }/$log_json/" /tmp/scalyr-agent-2.0.11/config/agent.json
sed -i "s/\/\/ serverHost: \"REPLACE THIS\",/serverHost: \"$APPLICATION_ID\"/" /tmp/scalyr-agent-2.0.11/config/agent.json
# scalyr-agent-2-config --set-user=$user_id
scalyr-agent-2 start