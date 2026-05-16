#!/bin/bash

# EDGE
docker network create \
	--driver bridge \
	--subnet 172.20.0.0/24 \
	edge-net

# APP
docker network create \
	--driver bridge \
	--subnet 172.21.0.0/24 \
	app-net

# DNS
docker network create \
	--driver bridge \
	--subnet 172.22.0.0/24 \
	dns-net

echo "Networks created successfully."
