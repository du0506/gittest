hostnameip=$(hostname -i)
realip=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}')
if [ $hostnameip == $realip ]
then
        echo "hostname passed"
else echo "请修改 hostname ！"
fi
