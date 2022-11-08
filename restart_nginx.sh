#!/bin/sh

ps aux | grep 'nginx: master process' | grep -v 'grep' | awk '{print $2}' | xargs kill &
sleep 5

echo "kill old worker process"
# ./recompile.sh nginx

numactl -C 100-$(($1+99)) ./build/nginx/sbin/nginx
WK_PID=(`ps aux | grep 'nginx: worker process' | grep -v 'grep' | awk '{print $2}'`)
echo ${WK_PID[@]}

# # Nuclear binding
# for(( i=0; i<${#WK_PID[@]}; i++)); do
#     stdbuf -oL echo "work process pid is " ${WK_PID[i]}
#     taskset -pc $i $WK_PID
# done;