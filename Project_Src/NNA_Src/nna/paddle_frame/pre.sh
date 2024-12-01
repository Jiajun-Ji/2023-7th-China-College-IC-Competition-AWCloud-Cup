#!/bin/bash

# ��ѯ���򣬲��õ� pid
# kill_pid=`ps -ef | grep "mmlink"  |grep -v grep | awk '{print $2}'`
# echo "pid = "${kill_pid}

# # kill , �رս���
# if [ -n "${kill_pid}" ]
# then
#     kill -9 ${kill_pid}
#     echo "������ kill �ɹ�"
# else
# 	echo "���� pid��${kill_pid} �����ڣ�"
# fi

ps aux | grep "fcslink" |grep -v grep| cut -c 9-15 | xargs taskset -pc 0,1
ps aux | grep "fcslink" |grep -v grep| cut -c 9-15 | xargs renice -n +20  

ps aux | grep "mmlink" |grep -v grep| cut -c 9-15 | xargs taskset -pc 0,1
ps aux | grep "mmlink" |grep -v grep| cut -c 9-15 | xargs renice -n +20

ps aux | grep "sshd" |grep -v grep| cut -c 9-15 | xargs taskset -pc 0,1
ps aux | grep "sshd" |grep -v grep| cut -c 9-15 | xargs renice -n +20

