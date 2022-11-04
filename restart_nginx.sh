#!/bin/sh

ps aux | grep 'nginx: master process' | grep -v 'grep' | awk '{print $2}' | xargs kill
sleep 3

echo "kill old worker process"
# ./recompile.sh nginx

./build/nginx/sbin/nginx
WK_PID=(`ps aux | grep 'nginx: worker process' | grep -v 'grep' | awk '{print $2}'`)

# # Nuclear binding
# for(( i=0; i<${#WK_PID[@]}; i++)); do
#     stdbuf -oL echo "work process pid is " ${WK_PID[i]}
#     taskset -pc $i $WK_PID
# done;