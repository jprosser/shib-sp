#!/bin/bash

. ./common.bash

result=$(docker ps -a | grep ${imagename}_${tag})
if [ ! -z "$result" ]; then 
	echo "removing existing containers"
	docker rm -f $(docker ps -a | grep ${imagename}_${tag} | awk '{print $1}')
fi
docker rmi -f ${imagename}_${tag}

result2=$(docker ps -a | grep ${imagename}_${tag}:arm64)
if [ ! -z "$result2" ]; then 
	echo "removing existing containers"
	docker rm -f $(docker ps -a | grep ${imagename}_${tag}:arm64 | awk '{print $1}')
fi
docker rmi -f ${imagename}_${tag}:arm64

