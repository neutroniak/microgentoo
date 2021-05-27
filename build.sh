#!/bin/sh

mv /usr/lib/python3.8/test .
mv /usr/lib64/node_modules/npm/docs .

buildah bud -f gentoo-container-base -t gentoo-container-base:latest
buildah bud -f gentoo-container-gcc -t gentoo-container-gcc:latest
buildah bud -f gentoo-container-python3 -t gentoo-container-python3:latest
buildah bud -f gentoo-container-nodejs -t gentoo-container-nodejs:latest
buildah bud -f gentoo-container-zeromq -t gentoo-container-zeromq:latest

mv test /usr/lib/python3.8/
mv docs /usr/lib64/node_modules/npm/

buildah push gentoo-container-base:latest ${REGISTRY_URL}/gentoo-container-base:latest
buildah push gentoo-container-gcc:latest ${REGISTRY_URL}/gentoo-container-gcc:latest
buildah push gentoo-container-python3:latest ${REGISTRY_URL}/gentoo-container-python3:latest
buildah push gentoo-container-nodejs:latest ${REGISTRY_URL}/gentoo-container-nodejs:latest
buildah push gentoo-container-zeromq:latest ${REGISTRY_URL}/gentoo-container-zeromq:latest

