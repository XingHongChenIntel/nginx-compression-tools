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

TEMP=0
SUM_REQ=0
SUM_THR=0

date +%F-%T >> ./performance/performance_report.log
for IP in ${IP_SET[@]};do
    echo $IP >> ./performance/performance_report.log

    TEMP=`awk '/^Requests per second:/{print $4}' ./performance/${IP}_test.log | awk '{sum+=$1}END{print sum}'`
    SUM_REQ=`echo "$TEMP + $SUM_REQ" | bc`

    awk '/^Requests per second:/{print $4}' ./performance/${IP}_test.log | awk -v result=$TEMP '{sum+=$1}END{print "-------------------- SUM------------------\n\
    The Totle CPS is == ",sum; $result=sum}' >> ./performance/performance_report.log

    TEMP=`awk '/^Transfer rate:/{print $3}' ./performance/${IP}_test.log | awk '{sum+=$1}END{printf("%d", sum)}'`
    SUM_THR=`echo "$TEMP + $SUM_THR" | bc`

    awk '/^Transfer rate:/{print $3}' ./performance/${IP}_test.log | awk '{sum+=$1}END{printf("The Totle throughput is == %d\n", sum)}' >> ./performance/performance_report.log
done

echo "9999999999999999999999999999999999999999999999" >> ./performance/performance_report.log
echo "FUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCK!!!!!!!!!! CPS is " $SUM_REQ >> ./performance/performance_report.log
echo "FUCKFUCKFUCKFUCKFUCKFUCKFUCKFUCK!!!!!!!!!! Throughput is " $SUM_THR >> ./performance/performance_report.log

# for IP in ${IP_SET[@]};do
#     echo $IP >> ./performance/performance_report.log
#     awk '/^Requests per second:|^Transfer rate:/ {print $0}' ./performance/${IP}_test.log >> ./performance/performance_report.log
# done
echo "Client execute done!"