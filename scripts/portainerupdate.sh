#!/bin/bash

docker stop portainer

docker rm portainer

docker pull portainer/portainer-ce:latest

docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /home/jaime/docker/portainer:/data portainer/portainer-ce:latest
