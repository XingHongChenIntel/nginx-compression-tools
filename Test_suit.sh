#!/bin/bash
source ./env_export.sh

# TESTFILE=(4K_index.html 8K_index.html 16K_index.html 32K_index.html \
#           64K_index.html 128K_index.html 256K_index.html 512K_index.html calgary.html)
# TESTFILE=(16K_index.html 32K_index.html 64K_index.html 128K_index.html 256K_index.html 512K_index.html calgary.html)
# TESTFILE=(4K_index.html 8K_index.html 16K_index.html 32K_index.html 64K_index.html 128K_index.html)
TESTFILE=(4K_index.html 8K_index.html)

# COM_PATH=(no gzip qatzip qatzip-zstd zstd zstd-qat)
COM_PATH=(qatzip)

# The different path and data should have diff REQ and Forkp
# gzip
# REQUEST=(2000 2000)
# CLIENT=100
# FORKP=(12 8 8)
# WORKNUM=(1)
echo "          " > ./performance/performance_report.log
# REQUEST=(3500 3000 2500 2000 1500 1000)
# REQUEST=(25000 20000 15000 12000 8000 5000)
REQUEST=(25000 20000)
CLIENT=100
WORKNUM=(48)
FORKP=(128)
# WORKNUM=(1 2 4 8 16 32 36 48 64 112)
# FORKP=(1 2 4 8 16 32 36 48 64 90)
# WORKNUM=(1 2 4 8 16)
# FORKP=(1 2 4 8 16)


function Test_pipeline() {
    # worker number / test file / compression path
    ./update_nginx_conf.sh $2 $3 $1
    ./restart_nginx.sh $2
    ./start_client.sh "$4"
}

# ./ab -n 900000 -c 1000 -r -M http://10.67.111.164:8081/
# ./ab -n 900000 -c 1000 -r -M -H "Accept-Encoding:gzip" http://10.67.111.164:8081/
# ./ab -n 900000 -c 1000 -r -M -H "Accept-Encoding:zstd" http://10.67.111.164:8081/
function ab_params_conf() {
case $1 in
    no)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r "
    ;;
    gzip)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:gzip\" "
    ;;
    qatzip)
        params="taskset -c 1-$4 $AB_PATH/ab -n $2 -c $3 -W $4 -r -H \"Accept-Encoding:gzip\" "
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

function Build_pipeline() {

    echo "!!!!!!!!!!!!!!! The path is $1 !!!!!!!!!!!!!!!" >> ./performance/performance_report.log

    for ((j=0; j<${#TESTFILE[@]}; j++));do

        echo "############### The test file is ${TESTFILE[j]} ###############" >> ./performance/performance_report.log

        for(( i=0; i<${#WORKNUM[@]}; i++)); do

            echo ";;;;;;;;;;;;;; The work number is ${WORKNUM[i]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log
            echo ";;;;;;;;;;;;;; The request number is ${REQUEST[j]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log
            echo ";;;;;;;;;;;;;; The fork AB number is ${FORKP[i]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log

            # ab_params=$(ab_params_conf $1 ${REQUEST[i]} ${CLIENT[i]} ${FORKP[i]})
            ab_params=$(ab_params_conf $1 ${REQUEST[j]} $CLIENT ${FORKP[i]})
            echo $ab_params
            Test_pipeline $1 ${WORKNUM[i]} ${TESTFILE[j]} "$ab_params"
        done;
    done;
}

# Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib
# Gzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)
# ZSTD QAT    : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (LZ4S + postprocessing)
# ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib
# ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-qat lib

# start whole process
date +%F-%T >> ./performance/performance_report.log

for job in ${COM_PATH[@]};do
    # compression path
    ./recompile.sh nginx $job
    Build_pipeline $job
done

# rm -rf ./build/nginx/logs