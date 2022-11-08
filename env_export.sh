#!/bin/sh

# configure the server compile && build path
export TOP_ROOT=`pwd`
export NG_ROOT=/home/xinghong/applications.qat.shims.nginx.async-mode-nginx
export QZ_ROOT=/home/xinghong/applications.qat.shims.qatzip.qatzip

export ZSTD_MODULE_PATH=/home/xinghong/zstd-nginx-module
export ZSTD_QAT_PATH=/home/xinghong/applications.qat.shims.zstandard.source
export ZSTD_ROOT=/home/xinghong/zstd
export NG_CONF=${TOP_ROOT}/nginx_conf/gzip.nginx.conf

mkdir -p ${TOP_ROOT}/build/openssl
mkdir -p ${TOP_ROOT}/build/nginx
mkdir -p ${TOP_ROOT}/build/qatzip
mkdir -p ${TOP_ROOT}/performance

# configure server port and ip
HOSTIP=(http://192.168.2.100:8081/  http://192.168.5.100:8081/ http://192.168.6.100:8081/)
# HOSTIP=(http://192.168.6.100:8081/)

# configure client port and ip
IP_SET=(10.67.110.232 10.67.111.136 10.67.110.221)
# IP_SET=(10.67.110.221)
USER=root
PSWORD=tester
AB_PATH="/home/xinghong/ApacheBench-ab/"
#export LD_LIBRARY_PATH=/home/xinghong/ApacheBench-ab/apr/apr-build/lib:/home/xinghong/ApacheBench-ab/apr/aprutil-build/lib:$LD_LIBRARY_PATH
