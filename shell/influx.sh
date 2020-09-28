#  安装脚本  docker_influxdb_install.sh
#! /bin/bash
#file:docker_influxdb_install.sh
#company:cvnavi.com
#author:Pengjunlin
echo "当前执行文件......$0"
IS_EXISTS_INFLUXDB_IMAGE_NAME="false"
IS_EXISTS_INFLUXDB_CONTAINER="false"
IS_EXISTS_INFLUXDB_CONTAINER_RUNGING="false"
START_CONTAINER_CHECK_MAX_TIMES=3
START_CONTAINER_CHECK_CURRENT=1
# ========================下载镜像======================================
for i in [ `docker images ` ]; do
	
	if [[ "$i" == "docker.io/influxdb" ||  "$i" == "influxdb" ]]; then
		echo "$i"
		IS_EXISTS_INFLUXDB_IMAGE_NAME="true"
		break
	fi
done
if [[ $IS_EXISTS_INFLUXDB_IMAGE_NAME == "true"  ]]; then
	echo "本地已存在influxdb:latest镜像，不再重新下载......."
else
	echo "本地不存在influxdb:latest镜像，正在下载......."
	docker pull influxdb:latest
fi
 
# ====================创建镜像===========================================
if [[ $IS_EXISTS_INFLUXDB_CONTAINER == "false" ]]; then
	echo "检查influxdb容器是否创建......"
	for i in [ `docker ps -a` ]; do
		if [[ "$i" == "influxdb" ]]; then
			IS_EXISTS_INFLUXDB_CONTAINER="true"
			break
		fi
	done
	if [[ $IS_EXISTS_INFLUXDB_CONTAINER == "false" ]]; then
		cp docker_influxdb_create_user.sh /etc/influxdb/scripts/docker_influxdb_create_user.sh
	    chmod a+x /etc/influxdb/scripts/docker_influxdb_create_user.sh
		if [[ -f "/etc/influxdb/scripts/docker_influxdb_create_user.sh" ]]; then
			echo "检查到influxdb容器尚未创建!"
	        # 执行容器创建
			# 运行容器实例 --privileged=true 获取管理员权限
			echo "创建influxdb容器实例..."
			sudo docker run -d -p 38083:8083 -p 38086:8086  --name influxdb  --restart always --privileged=true -v /etc/influxdb/scripts:/etc/influxdb/scripts  influxdb:latest
			# 休10秒钟
			echo "休眠等待10s以便Docker完成容器运行......"
			sleep 10s
	        echo "进入influxdb容器: docker exec -it influxdb  /bin/bash -c 'sh /etc/influxdb/scripts/docker_influxdb_create_user.sh'"
			# 进入容器并执行脚本：
			docker exec -it influxdb  /bin/bash -c "sh /etc/influxdb/scripts/docker_influxdb_create_user.sh"
			# 删除执行文件
			rm -f /etc/influxdb/scripts/docker_influxdb_create_user.sh
 
			echo "influxdb容器已创建完毕!"
 
			IS_EXISTS_INFLUXDB_CONTAINER_RUNGING=true
		else
			echo "/etc/influxdb/scripts/docker_influxdb_create_user.sh文件不存在，docker需要用此文件创建influxdb容器实例并创建用户."
			exit 1
		fi
	else
		echo "检查到influxdb容器已创建!"
	fi
fi
# ===================启动或重启容器================================
if [[ $IS_EXISTS_INFLUXDB_CONTAINER == "true" && $IS_EXISTS_INFLUXDB_CONTAINER_RUNGING == "false" ]]; then
    echo "下面最多执行三次influxdb容器检查重启..."
	while [[ $START_CONTAINER_CHECK_CURRENT -le $START_CONTAINER_CHECK_MAX_TIMES ]]; do
		echo "检查influxdb容器状态......$START_CONTAINER_CHECK_CURRENT"
		for i in [ `docker ps ` ]; do
			if [[ "$i" == "influxdb" ]]; then
				IS_EXISTS_INFLUXDB_CONTAINER_RUNGING="true"
				break
			fi
		done
		if [[ $IS_EXISTS_INFLUXDB_CONTAINER_RUNGING == "false" ]]; then
			echo "检查到influxdb容器当前不在运行状态!"
			echo "启动influxdb容器...."
			docker start influxdb
			for i in [ `docker ps ` ]; do
				if [[ "$i" == "influxdb" ]]; then
					IS_EXISTS_INFLUXDB_CONTAINER_RUNGING="true"
					break
				fi
			done
			if [[ $IS_EXISTS_INFLUXDB_CONTAINER_RUNGING == "true" ]]; then
				echo "influxdb容器已经在运行!"
				break
			fi
		else
			echo "influxdb容器已经在运行!"
			break
		fi
		START_CONTAINER_CHECK_CURRENT=$((START_CONTAINER_CHECK_CURRENT+1))
	done
	if [[ $IS_EXISTS_INFLUXDB_CONTAINER_RUNGING == "false" ]]; then
		echo "检查到influxdb容器当前仍未运行,请联系相关人员进行处理!"
		exit 1
	fi
fi



############## 数据库操作脚本 docker_influxdb_create_user.sh #############

#！/bin/bash
#file:docker_influxdb_create_user.sh
#company:cvnavi.com
#author:Pengjunlin
echo "当前执行文件......$0"
INFLUXDB_DATABASE_NAME="rtvsweb"
INFLUXDB_USER_NAME="admin"
INFLUXDB_USER_PWD="admin"
# influxdb数据库相关配置
echo "influxdb数据库相关配置"
influx -version
# 查询数据库列表
echo "查询数据库列表"
influx  -execute "show databases"
# 删除数据库
echo "删除数据库$INFLUXDB_DATABASE_NAME"
influx  -execute "drop database $INFLUXDB_DATABASE_NAME"
# 创建数据库
echo "创建数据库$INFLUXDB_DATABASE_NAME"
influx  -execute "create database $INFLUXDB_DATABASE_NAME"
# 创建用户并授权
echo "创建$INFLUXDB_USER_NAME用户并授权"
influx -execute "create user "$INFLUXDB_USER_NAME" with password '$INFLUXDB_USER_PWD' with all privileges"
# 查询用户列表
echo "查询用户列表"
influx -execute "use $INFLUXDB_DATABASE_NAME" -execute  "show users"
