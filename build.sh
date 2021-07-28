#!/bin/sh

export GCC_VERSION=$(gcc --version |rev |grep ccg|awk '{print $1}'|rev)
export PYTHON_VERSION="3.9"

mv /usr/lib/python${PYTHON_VERSION}/test .
mv /usr/lib/python${PYTHON_VERSION}/site-packages .
mkdir /usr/lib/python${PYTHON_VERSION}/site-packages
cp site-packages/epython.py /usr/lib/python${PYTHON_VERSION}/site-packages/

mv /usr/lib64/node_modules/npm/docs .

buildah bud --build-arg GCC_VERSION=$GCC_VERSION -f gentoo-container-base -t gentoo-container-base:latest
buildah bud --build-arg GCC_VERSION=$GCC_VERSION -f gentoo-container-gcc -t gentoo-container-gcc:latest
buildah bud --build-arg PYTHON_VERSION=$PYTHON_VERSION -f gentoo-container-python3 -t gentoo-container-python3:latest
buildah bud -f gentoo-container-nodejs -t gentoo-container-nodejs:latest
buildah bud -f gentoo-container-zeromq -t gentoo-container-zeromq:latest
buildah bud -f gentoo-container-nginx -t gentoo-container-nginx:latest
buildah bud -f gentoo-container-packer -t gentoo-container-packer:latest
buildah bud -f gentoo-container-openssh -t gentoo-container-openssh:latest
buildah bud -f gentoo-container-git -t gentoo-container-git:latest

mv test /usr/lib/python${PYTHON_VERSION}/
rm -rf /usr/lib/python${PYTHON_VERSION}/site-packages
mv site-packages /usr/lib/python${PYTHON_VERSION}/
mv docs /usr/lib64/node_modules/npm/

buildah push ${REGISTRY_ARGS} gentoo-container-base:latest ${REGISTRY_URL}/gentoo-container-base:latest
buildah push ${REGISTRY_ARGS} gentoo-container-gcc:latest ${REGISTRY_URL}/gentoo-container-gcc:latest
buildah push ${REGISTRY_ARGS} gentoo-container-python3:latest ${REGISTRY_URL}/gentoo-container-python3:latest
buildah push ${REGISTRY_ARGS} gentoo-container-nodejs:latest ${REGISTRY_URL}/gentoo-container-nodejs:latest
buildah push ${REGISTRY_ARGS} gentoo-container-zeromq:latest ${REGISTRY_URL}/gentoo-container-zeromq:latest
buildah push ${REGISTRY_ARGS} gentoo-container-packer:latest ${REGISTRY_URL}/gentoo-container-packer:latest
buildah push ${REGISTRY_ARGS} gentoo-container-openssh:latest ${REGISTRY_URL}/gentoo-container-openssh:latest
buildah push ${REGISTRY_ARGS} gentoo-container-git:latest ${REGISTRY_URL}/gentoo-container-git:latest

