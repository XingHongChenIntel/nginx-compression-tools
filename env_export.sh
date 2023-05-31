#!/bin/sh

# configure the server compile && build path
export TOP_ROOT=`pwd`
export NG_ROOT=/your/async-mode-nginx/path
export QZ_ROOT=/your/qatzip/path

export ZSTD_MODULE_PATH=/your/zstd-modlue/path
export ZSTD_QAT_PATH=/your/zstd-plugin/path
export ZSTD_ROOT=/your/zstd/path

mkdir -p ${TOP_ROOT}/build/openssl
mkdir -p ${TOP_ROOT}/build/nginx
mkdir -p ${TOP_ROOT}/build/qatzip
mkdir -p ${TOP_ROOT}/performance

# configure server port and ip
HOSTIP=(put your host IP here, you can put multi-host)

# configure client port and ip
IP_SET=(put your client here, its number must equel with host ip)

# put your client wrk configure here
USER=root
PSWORD=your/passwork
AB_PATH="your AB path"
WRK_PATH="your wrk path"
