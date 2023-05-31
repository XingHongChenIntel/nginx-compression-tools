#!/bin/bash
source ./env_export.sh

TESTFILE=(put your all html file here)
COM_PATH=(no gzip qatzip zstd zstd-qat)

# It should be relative with test file size
# This is for AB client, it means the totally request you want send.
REQUEST=(10 10 10 10 10)
# This is for keep-alive connenction, means how many connection you want to keep.
CLIENT=(200 200 200 200 200)

# The different path and data should have diff REQ and Forkp
# This is for client, how many thread, you want to use
FORKP=(36 36 36 36 36 36 36 36 36 48)
# This is nginx worker process number
WORKNUM=(1 2 4 8 16 32 36 48 64 112)

echo "     cxh     " > ./performance/performance_report.log
echo "     cxh     " > ./performance/performance_report_summary.log

function Test_pipeline() {
    # worker number / test file / compression path
    ./recompile.sh nginx $1
    ./update_nginx_conf.sh $2 $3 $1
    ./restart_nginx.sh $2
    ./start_client.sh $1 $4 $5 $6
}

function Build_pipeline() {

    echo "!!!!!!!!!!!!!!! The path is $1 !!!!!!!!!!!!!!!" >> ./performance/performance_report.log

    for ((j=0; j<${#TESTFILE[@]}; j++));do

        echo "############### The test file is ${TESTFILE[j]} ###############" >> ./performance/performance_report.log

        for(( i=0; i<${#WORKNUM[@]}; i++)); do

            echo ";;;;;;;;;;;;;; The work number is ${WORKNUM[i]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log
            echo ";;;;;;;;;;;;;; The connection number is ${CLIENT[j]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log
            echo ";;;;;;;;;;;;;; The client thread number is ${FORKP[i]} ;;;;;;;;;;;;;;" >> ./performance/performance_report.log

            Test_pipeline $1 ${WORKNUM[i]} ${TESTFILE[j]} ${REQUEST[j]} ${CLIENT[j]} ${FORKP[i]}
        done;
    done;
}

# Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib
# Gzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)
# ZSTD QAT    : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (LZ4S + postprocessing)
# ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib
# ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-plugin lib

# start whole process
date +%F-%T >> ./performance/performance_report.log

for job in ${COM_PATH[@]};do
    # compression path
    Build_pipeline $job
done

# rm -rf ./build/nginx/logs