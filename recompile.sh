#!/bin/sh
source ./env_export.sh

compile_qatzip() {
    echo "Recompile qatzip"
    cd $QZ_ROOT
    git checkout master

    ./autogen.sh
    ./configure \
    --prefix=${TOP_ROOT}/build/qatzip \
    --with-ICP_ROOT=$ICP_ROOT \
    --enable-lz4s-postprocessing

    make clean
    make all -j
    make uninstall
    make install -j
    cd $TOP_ROOT
}

compile_zstd() {
    echo "Recompile zstd"
    cd $ZSTD_ROOT
    git checkout v1.5.4

    make clean
    make -j
    rm -rf $ZSTD_ROOT/lib/libzstd.a
    cd $TOP_ROOT
}

compile_plugin() {
    echo "Recompile plugin"
    cd $ZSTD_QAT_PATH
    export ZSTDLIB=$ZSTD_ROOT/lib
    git checkout main

    make clean
    make ENABLE_USDM_DRV=1
    cd $TOP_ROOT
}

# Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib
# Gzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)
# ZSTD QAT    : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (LZ4S + postprocessing)
# ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib
# ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-qat lib

compile_nginx() {
    echo "Recompile Nginx"
    cd $NG_ROOT
    make clean
    ldconfig

case $1 in
    no)
        echo "No compression : Async nignx  -->  html"
        # For no compression nginx
            ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx  \
        --with-http_ssl_module \
        --without-http_gzip_module \
        --with-cc-opt="-DNGX_SECURE_MEM -Wno-error=deprecated-declarations"
    ;;

    gzip)
        echo "Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib"
            ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx  \
        --with-http_ssl_module \
        --with-cc-opt="-DNGX_SECURE_MEM -Wno-error=deprecated-declarations"
    ;;

    qatzip)
        echo "QATzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)/stream API (LZ4S + postprocessing) "
            ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx  \
        --with-http_ssl_module \
        --without-http_gzip_module \
        --add-dynamic-module=modules/nginx_qatzip_module \
        --with-cc-opt="-DNGX_SECURE_MEM -I$ICP_ROOT/quickassist/include -I$ICP_ROOT/quickassist/include/dc -I$QZ_ROOT/include -Wno-error=deprecated-declarations" \
        --with-ld-opt="-Wl,-rpath=$TOP_ROOT/build/qatzip/lib -L$TOP_ROOT/build/qatzip/lib -lqatzip -lz -lrt -lzstd"
    ;;

    qatzip-zstd)
        echo "QATzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)/stream API (LZ4S + postprocessing) "
            ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx  \
        --with-http_ssl_module \
        --without-http_gzip_module \
        --add-dynamic-module=modules/nginx_qatzip_module \
        --with-cc-opt="-DNGX_SECURE_MEM -I$ICP_ROOT/quickassist/include -I$ICP_ROOT/quickassist/include/dc -I$QZ_ROOT/include -Wno-error=deprecated-declarations" \
        --with-ld-opt="-Wl,-rpath=$TOP_ROOT/build/qatzip/lib -L$TOP_ROOT/build/qatzip/lib -lqatzip -lz -lrt -lzstd"
    ;;

    zstd)
        echo "ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib"
        ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx \
        --with-http_ssl_module \
        --without-http_gzip_module \
        --add-module=$ZSTD_MODULE_PATH \
        --with-cc-opt="-DNGX_SECURE_MEM -I$ZSTD_ROOT/lib -Wno-error=deprecated-declarations" \
        --with-ld-opt="-Wl,-rpath=$ZSTD_ROOT/lib -L$ZSTD_ROOT/lib -lzstd"
    ;;

    zstd-qat)
        echo "ZSTD-PATCH    :Async nignx  -->  zstd-nginx-module --> zstd-qat lib"
        ./configure \
        --with-debug --with-cc-opt=' -O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx \
        --with-http_ssl_module \
        --without-http_gzip_module \
        --add-module=$ZSTD_MODULE_PATH \
        --with-cc-opt="-DNGX_SECURE_MEM -I$ICP_ROOT/quickassist/include -I$ICP_ROOT/quickassist/include/dc -I$ZSTD_ROOT/lib -I$ZSTD_QAT_PATH/src -Wno-error=deprecated-declarations" \
        --with-ld-opt="-Wl,-rpath=$ZSTD_ROOT/lib -L$ZSTD_ROOT/lib -lzstd -lqat_s -lusdm_drv_s -L$ZSTD_QAT_PATH/src -l:libqatseqprod.a"
    ;;

    *)  echo "recompile nginx nothing apointed"
        echo "Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib"
            ./configure \
        --with-debug --with-cc-opt='-O0 -g' \
        --prefix=${TOP_ROOT}/build/nginx  \
        --with-http_ssl_module \
        --with-cc-opt="-DNGX_SECURE_MEM -Wno-error=deprecated-declarations"
    ;;
esac

    make -j
    make install -j
    cd $TOP_ROOT
}


case $1 in
    qatzip)
        compile_qatzip
    ;;

    nginx)
        compile_nginx $2
    ;;

    zstd)
        compile_zstd
    ;;

    zstd-plugin)
        compile_plugin
    ;;

    all)
        echo "Recompile all"
        compile_qatzip
        compile_nginx
    ;;

    *) echo "nothing apointed"
    ;;
esac

