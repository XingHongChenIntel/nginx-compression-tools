#!/bin/bash
source ./env_export.sh

#AB_PATH=$1 HOSTIP=$2 RS=$3 CS=$4
# we force use the ab as client pressure tools, otherwise performance file will run into trouble
ABPARM="$1"
echo $ABPARM

STORE_FD=$AB_PATH/test.log
CMD_AB="stdbuf -oL $AB_PATH/$ABPARM $HOSTIP > $STORE_FD"

REMOTE_SH=./remote_exec.sh
COPY_FILE=./copy_file.sh

echo $CMD_AB
for IP in ${IP_SET[@]};do
    $REMOTE_SH $IP $USER $PSWORD "${CMD_AB}" &
done

wait

for IP in ${IP_SET[@]};do
    $COPY_FILE $IP $USER $PSWORD $STORE_FD ./performance/${IP}_test.log &
done

wait

date +%F-%T >> ./performance/performance_report.log
for IP in ${IP_SET[@]};do
    echo $IP >> ./performance/performance_report.log
    awk '/^Requests per second:|^Transfer rate:/ {print $0}' ./performance/${IP}_test.log >> ./performance/performance_report.log
done
echo "Client execute done!"