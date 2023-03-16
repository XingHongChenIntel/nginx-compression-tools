#!/bin/bash
source ./env_export.sh

# TESTFILE=(16K_index.html 32K_index.html 64K_index.html 128K_index.html 256K_index.html 512K_index.html calgary.html)
# TESTFILE=(4K_index.html 8K_index.html 16K_index.html 32K_index.html 64K_index.html 128K_index.html)
TESTFILE=(4K_index.html)

# COM_PATH=(no gzip qatzip qatzip-zstd zstd zstd-qat)
COM_PATH=(gzip)

echo "          " >> ./performance/performance_report.log
# The different path and data should have diff REQ and Forkp
REQUEST=(10)
CLIENT=(200)

WORKNUM=(1)
FORKP=(4)
# REQUEST=(3500 3000 2500 2000 1500 1000)
# REQUEST=(25000 20000 15000 8000 5000 2000)
# WORKNUM=(1 2 4 8 16 32 36 48 64 112)
# FORKP=(1 2 4 8 16 32 36 48 64 90)

function Test_pipeline() {
    # worker number / test file / compression path
    # ./recompile.sh nginx $1
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
# ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-qat lib

# start whole process
date +%F-%T >> ./performance/performance_report.log

for job in ${COM_PATH[@]};do
    # compression path
    ./recompile.sh nginx $job
    Build_pipeline $job
done

# rm -rf ./build/nginx/logs