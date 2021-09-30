#!/bin/sh

export GCC_VERSION=$(gcc --version |rev |grep ccg|awk '{print $1}'|rev)
export PYTHON_VERSION=$(python -V|awk '{print $2}'|awk -F"." '{print $1"."$2}')
export RUBY_VERSION=$(ruby -v |awk '{print $2}'|awk -F "." '{print $1"."$2}')
export PHP_VERSION=$(php -v |awk '/^PHP/ {print $2}'|awk -F "." '{print $1"."$2}')

export RUBY_VERSION_ALPHA=${RUBY_VERSION/\./}

cp gentoo-container-* busybox.sh passwd group /

OLDPWD=$(pwd)
cd /

mv /usr/lib/python${PYTHON_VERSION}/test .
mv /usr/lib/python${PYTHON_VERSION}/site-packages .
mkdir /usr/lib/python${PYTHON_VERSION}/site-packages
cp site-packages/epython.py /usr/lib/python${PYTHON_VERSION}/site-packages/

mv /usr/lib64/node_modules/npm/docs .

buildah bud --build-arg GCC_VERSION=$GCC_VERSION -f gentoo-container-base -t gentoo-container-base:latest
buildah bud --build-arg GCC_VERSION=$GCC_VERSION -f gentoo-container-gcc -t gentoo-container-gcc:latest
buildah bud --build-arg PYTHON_VERSION=$PYTHON_VERSION -f gentoo-container-python -t gentoo-container-python:latest
buildah bud -f gentoo-container-nodejs -t gentoo-container-nodejs:latest
buildah bud -f gentoo-container-zeromq -t gentoo-container-zeromq:latest
buildah bud -f gentoo-container-nginx -t gentoo-container-nginx:latest
buildah bud -f gentoo-container-packer -t gentoo-container-packer:latest
buildah bud -f gentoo-container-openssh -t gentoo-container-openssh:latest
buildah bud -f gentoo-container-git -t gentoo-container-git:latest
buildah bud -f gentoo-container-openjdk -t gentoo-container-openjdk:latest
buildah bud --build-arg RUBY_VERSION=${RUBY_VERSION_ALPHA} -f gentoo-container-ruby -t gentoo-container-ruby:latest
buildah bud --build-arg PHP_VERSION=${PHP_VERSION} -f gentoo-container-php -t gentoo-container-php:latest

mv test /usr/lib/python${PYTHON_VERSION}/
rm -rf /usr/lib/python${PYTHON_VERSION}/site-packages
mv site-packages /usr/lib/python${PYTHON_VERSION}/
mv docs /usr/lib64/node_modules/npm/

buildah push ${REGISTRY_ARGS} gentoo-container-base:latest ${REGISTRY_URL}/gentoo-container-base:latest
buildah push ${REGISTRY_ARGS} gentoo-container-gcc:latest ${REGISTRY_URL}/gentoo-container-gcc:latest
buildah push ${REGISTRY_ARGS} gentoo-container-python:latest ${REGISTRY_URL}/gentoo-container-python:latest
buildah push ${REGISTRY_ARGS} gentoo-container-nodejs:latest ${REGISTRY_URL}/gentoo-container-nodejs:latest
buildah push ${REGISTRY_ARGS} gentoo-container-zeromq:latest ${REGISTRY_URL}/gentoo-container-zeromq:latest
buildah push ${REGISTRY_ARGS} gentoo-container-packer:latest ${REGISTRY_URL}/gentoo-container-packer:latest
buildah push ${REGISTRY_ARGS} gentoo-container-openssh:latest ${REGISTRY_URL}/gentoo-container-openssh:latest
buildah push ${REGISTRY_ARGS} gentoo-container-git:latest ${REGISTRY_URL}/gentoo-container-git:latest
buildah push ${REGISTRY_ARGS} gentoo-container-openjdk:latest ${REGISTRY_URL}/gentoo-container-openjdk:latest
buildah push ${REGISTRY_ARGS} gentoo-container-ruby:latest ${REGISTRY_URL}/gentoo-container-ruby:latest
buildah push ${REGISTRY_ARGS} gentoo-container-php:latest ${REGISTRY_URL}/gentoo-container-php:latest

rm gentoo-container-* busybox.sh passwd group
cd $OLDPWD


