#!/bin/bash
source ./env_export.sh

#AB_PATH=$1 HOSTIP=$2 RS=$3 CS=$4
# we force use the ab as client pressure tools, otherwise performance file will run into trouble
ABPARM="$1"
echo $ABPARM
REMOTE_SH=./remote_exec.sh
COPY_FILE=./copy_file.sh

STORE_FD=$AB_PATH/test.log
CMD_AB="stdbuf -oL $ABPARM"

echo $CMD_AB
for ((i=0; i<${#IP_SET[@]}; i++));do
# for IP in ${IP_SET[@]};do
    $REMOTE_SH ${IP_SET[i]} $USER $PSWORD "${CMD_AB} ${HOSTIP[i]} > $STORE_FD" &
done

wait

for IP in ${IP_SET[@]};do
    $COPY_FILE $IP $USER $PSWORD $STORE_FD ./performance/${IP}_test.log &
done

wait

date +%F-%T >> ./performance/performance_report.log
for IP in ${IP_SET[@]};do
    echo $IP >> ./performance/performance_report.log
    awk '/^Requests per second:/{print $4}' ./performance/${IP}_test.log | awk '{sum+=$1}END{print "-------------------- SUM------------------\n\
    The Totle CPS is == ",sum}' >> ./performance/performance_report.log
    awk '/^Transfer rate:/{print $3}' ./performance/${IP}_test.log | awk '{sum+=$1}END{print "The Totle throughput is == ",sum}' >> ./performance/performance_report.log
done

for IP in ${IP_SET[@]};do
    echo $IP >> ./performance/performance_report.log
    awk '/^Requests per second:|^Transfer rate:/ {print $0}' ./performance/${IP}_test.log >> ./performance/performance_report.log
done
echo "Client execute done!"