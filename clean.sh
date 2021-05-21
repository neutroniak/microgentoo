#!/bin/sh

echo "Clean unused containers..."
podman rm $(podman ps -a|grep Exited | awk '{print $1}')

echo "Clean unused images..."
buildah rmi --prune

