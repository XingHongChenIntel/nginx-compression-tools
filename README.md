This is a script suit, it's for compression nginx performance test.
Hope it can make everything more smooth.

There are three part of suit.
1.  compile and conf nginx properly (recompile.sh and update_nginx_conf.sh)
    Because there are five diff path to run compression nginx. so you can add more path conf here.
    # Gzip SW       : Async nignx  -->  ngx_http_gzip_filter_module --> zlib
    # Gzip QAT      : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (DEFLATE_RAW)
    # ZSTD QAT    : Async nignx  -->  ngx_http_qatzip_filter_module --> qatzip lib --> stream API (LZ4S + postprocessing)
    # ZSTD SW      : Async nignx  -->  zstd-nginx-module --> zstd lib
    # ZSTD-PATCH    : Async nignx  -->  zstd-nginx-module --> zstd-qat lib
    which will be represent by those symbol for swich check:
    no/gzip/qatzip/qatzip-zstd/zstd/zstd-qat

2.  start nginx and start client (restart_nginx.sh / start_client.sh)
    it can help to run the nginx on server, and pull request from client.

3.  Setup ENV and Test suit properly
    set right env into env_export.sh, set Test suit into Test_suit.sh

The report will be generate in performance file.
And please don't change the dictionary structure.

update drvier
$QZ_TOOL/install_drv/install_upstream.sh

client machine
#export LD_LIBRARY_PATH=/home/xinghong/ApacheBench-ab/apr/apr-build/lib:/home/xinghong/ApacheBench-ab/apr/aprutil-build/lib:$LD_LIBRARY_PATH

Component:
nginx: https://github.com/intel-innersource/applications.qat.shims.nginx.async-mode-nginx.git / dev_xinghong_QATAPP-27166_support_zstd_compress
qatzip: https://github.com/intel-innersource/applications.qat.shims.qatzip.qatzip.git / master

zstd-nginx-module: https://github.com/XingHongChenIntel/zstd-nginx-module.git / zstd_plugin_new_api_common_ctx or zstd_new_api_common_cctx
/* For zstd-nginx-module, if test zstd path, use zstd_new_api_common_cctx branch,
/* if test zstd_plugin use zstd_plugin_new_api_common_ctx branch
*/

zstd: https://github.com/facebook/zstd.git / v1.5.4
zstd-plugin: https://github.com/intel-collab/applications.qat.shims.zstandard.qatzstdplugin.git / master

The run step:

pre-request:
build all your component one by one, you can use the recompile.sh

1. correctly set the component path and ip address in env_export.sh
2. correctly set your test suit config in Test_suit.sh file
3. you may need to cp all your tested html file to build/nginx/html
4. run Test_suit.sh
5. you can check the result under performance dictionary