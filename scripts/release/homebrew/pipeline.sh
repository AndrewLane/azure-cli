#!/bin/bash

root=$(cd $(dirname $0); pwd)

set -e

CLI_VERSION=`cat $SYSTEM_ARTIFACTSDIRECTORY/metadata/version`
HOMEBREW_UPSTREAM_URL=`cat $BUILD_STAGINGDIRECTORY/github/upstream_url`
TAR_NAME=azure-cli-$CLI_VERSION.tar.gz

docker_files=$(cd $root/docker; pwd)
pypi_files=$(cd $SYSTEM_ARTIFACTSDIRECTORY/pypi; pwd)

# get a random string of 32 characters
container_name=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z0-9' | fold -w 32 | head -n 1)

echo "Generating formula in docker container ... "
docker run -v $docker_files:/mnt/scripts \
           -v $pypi_files:/mnt/pypi \
           -e CLI_VERSION=$CLI_VERSION \
           -e HOMEBREW_UPSTREAM_URL=$HOMEBREW_UPSTREAM_URL \
           --name $container_name \
           python:3.6 \
           /mnt/scripts/run.sh

docker cp $container_name:azure-cli.rb $BUILD_STAGINGDIRECTORY/azure-cli.rb
docker rm $container_name
