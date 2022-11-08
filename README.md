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
    no/gzip/qatzip/zstd/zstd-qat

2.  start nginx and start client (restart_nginx.sh / start_client.sh)
    it can help to run the nginx on server, and pull request from client.
    please add your avaliable client into start_client.sh script.

3.  Setup ENV and Test suit properly
    set right env into env_export.sh, set Test suit into Test_suit.sh

The report will be generate in performance file.
And please don't change the dictionary structure.

update drvier
$QZ_TOOL/install_drv/install_upstream.sh