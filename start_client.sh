#!/bin/bash
source ./env_export.sh

# ./ab -n 900000 -c 1000 -r -M http://10.67.111.164:8081/
# ./ab -n 900000 -c 1000 -r -M -H "Accept-Encoding:gzip" http://10.67.111.164:8081/
# ./ab -n 900000 -c 1000 -r -M -H "Accept-Encoding:zstd" http://10.67.111.164:8081/
function ab_params_conf() {
case $1 in
    no)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r "
    ;;
    gzip)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -k -H \"Accept-Encoding: gzip\" "
    ;;
    qatzip)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -k -H \"Accept-Encoding: gzip\" "
    ;;
    qatzip-zstd)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:zstd\" "
    ;;
    zstd)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:zstd\" "
    ;;
    zstd-qat)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:zstd\" "
    ;;
    *)  echo "client ab params nothing apointed"
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:gzip\" "
    ;;
esac
    echo $params
}

function wrk_params_conf() {
case $1 in
    no)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: gzip\" "
    ;;
    gzip)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: gzip\" "
    ;;
    qatzip)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: gzip\" "
    ;;
    qatzip-zstd)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: zstd\" "
    ;;
    zstd)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: zstd\" "
    ;;
    zstd-qat)
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: zstd\" "
    ;;
    *)  echo "client ab params nothing apointed"
        params="taskset -c 1-$4 $WRK_PATH/wrk -c $3 -t $4 -d15s -H \"Accept-Encoding: gzip\" "
    ;;
esac
    echo $params
}

function count_performance() {
    TEMP=0
    VAR=GB
    NUM=0
    SUM_REQ=0
    SUM_THR=0

    date +%F-%T >> ./performance/performance_report.log
    for IP in ${IP_SET[@]};do
        echo $IP >> ./performance/performance_report.log

        TEMP=`awk '/^Requests\/sec:/{print $2}' ./performance/${IP}_test.log | awk '{sum+=$1}END{print sum}'`
        # TEMP=`awk '/^Requests per second:/{print $4}' ./performance/${IP}_test.log | awk '{sum+=$1}END{print sum}'`
        SUM_REQ=`echo "$TEMP + $SUM_REQ" | bc`

        awk '/^Requests\/sec:/{print $2}' ./performance/${IP}_test.log |
        awk -v result=$TEMP '{sum+=$1}END{print "RPS: ", sum; $result=sum}' >> ./performance/performance_report.log
        # awk '/^Requests per second:/{print $4}' ./performance/${IP}_test.log | awk -v result=$TEMP '{sum+=$1}END{print "-------------------- SUM------------------\n\
        # The Totle CPS is == ",sum; $result=sum}' >> ./performance/performance_report.log

        TEMP=`awk '/^Transfer\/sec:/{print $2}' ./performance/${IP}_test.log`
        VAR=`echo $TEMP | tr -d '[0-9.]'`
        NUM=`echo $TEMP | tr -cd '[0-9.]'`
        # TEMP=`awk '/^Transfer rate:/{print $3}' ./performance/${IP}_test.log | awk '{sum+=$1}END{printf("%d", sum)}'`
        SUM_THR=`echo "$NUM + $SUM_THR" | bc`
        echo "Throughput: $TEMP" >> ./performance/performance_report.log
        # awk '/^Transfer rate:/{print $3}' ./performance/${IP}_test.log | awk '{sum+=$1}END{printf("The Totle throughput is == %d\n", sum)}' >> ./performance/performance_report.log
    done

    echo "-------------------- SUM------------------" >> ./performance/performance_report.log
    echo "RPS is " $SUM_REQ >> ./performance/performance_report.log
    echo "Throughput is " $SUM_THR $VAR >> ./performance/performance_report.log

    echo $SUM_REQ  $SUM_THR $VAR >> ./performance/performance_report_summary.log
    # for IP in ${IP_SET[@]};do
    #     echo $IP >> ./performance/performance_report.log
    #     awk '/^Requests per second:|^Transfer rate:/ {print $0}' ./performance/${IP}_test.log >> ./performance/performance_report.log
    # done
}


#AB_PATH=$1 HOSTIP=$2 RS=$3 CS=$4
# we force use the ab as client pressure tools, otherwise performance file will run into trouble
REMOTE_SH=./remote_exec.sh
COPY_FILE=./copy_file.sh

CPARM=" $(wrk_params_conf $1 $2 $3 $4) "
# CPARM=" $(ab_params_conf $1 $2 $3 $4) "
echo $CPARM
STORE_FD=${WRK_PATH}/test.log
CMD_AB="stdbuf -oL $CPARM"
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

count_performance

echo "Client execute done!"