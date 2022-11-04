#!/bin/bash

#generate temp file for nginx
TEMPLETE=./nginx_conf/Templete_nginx.conf
F_TEMP=./nginx_conf/${RANDOM}_temp.conf
cp $TEMPLETE $F_TEMP

function update_index_file() {
    sed -i "s/index .*;/index  $1;/" $F_TEMP
}

function update_worker() {
    sed -i "s/^worker_processes.*;/worker_processes  $1;/" $F_TEMP
}

function insert_load_module() {
    sed -i "/worker_rlimit_nofile/a\ $1" $F_TEMP
}

function insert_http_conf() {
    echo $1
    sed -i "/keepalive_timeout/a\ $1" $F_TEMP
}

# Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib
# Gzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)
# ZSTD QAT    : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (LZ4S + postprocessing)
# ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib
# ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-qat lib

function update_conf() {

case $1 in
    no)
        conf_ins="\t #No instructions about compression\n"
    ;;

    gzip)
        conf_ins="   gzip_http_version   1.0;\n\
    gzip on;\n\
    gzip_min_length     128;\n\
    gzip_comp_level     1;\n\
    gzip_vary            on;\n\
    gzip_disable        msie6;\n"
    ;;

    qatzip)
        conf_ins="   gzip_http_version   1.0;\n\
    qatzip_sw no;\n\
    qatzip_min_length 128;\n\
    qatzip_buffers 16 8k;\n\
    qatzip_chunk_size   64k;\n\
    qatzip_stream_size  256k;\n\
    qatzip_sw_threshold 256;\n\
    qatzip_comp_level   1;\n\
    qatzip_polling_mode busy;\n"

    insert_load_module "load_module modules/ngx_http_qatzip_filter_module.so;"
    ;;

    qatzip-zstd)
        conf_ins="   gzip_http_version   1.0;\n\
    qatzip_sw no;\n\
    qatzip_min_length 128;\n\
    qatzip_buffers 16 8k;\n\
    qatzip_chunk_size   64k;\n\
    qatzip_stream_size  256k;\n\
    qatzip_sw_threshold 256;\n\
    qatzip_comp_level   1;\n\
    qatzip_polling_mode busy;\n"

    insert_load_module "load_module modules/ngx_http_qatzip_filter_module.so;"
    ;;

    zstd)
        conf_ins="    gzip_http_version   1.0;\n\
    zstd on;\n\
    zstd_min_length 256; # no less than 256 bytes\n\
    zstd_comp_level 1; # set the level to 3\n"
    ;;

    zstd-qat)
        conf_ins="    gzip_http_version   1.0;\n\
    zstd on;\n\
    zstd_min_length 256; # no less than 256 bytes\n\
    zstd_comp_level 1; # set the level to 3\n"
    ;;

    *)  echo "update conf nothing apointed"
        conf_ins="   gzip_http_version   1.0;\n\
    gzip on;\n\
    gzip_min_length     128;\n\
    gzip_comp_level     1;\n\
    gzip_vary            on;\n\
    gzip_disable        msie6;\n"
    ;;
esac
    insert_http_conf "$conf_ins"
}

# update worker / update file / update instructions
update_worker $1
update_index_file $2
update_conf $3

cp $F_TEMP ./build/nginx/conf/nginx.conf
rm -rf $F_TEMP