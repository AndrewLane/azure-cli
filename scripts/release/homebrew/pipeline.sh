#!/bin/bash

root=$(cd $(dirname $0); pwd)

set -e

CLI_VERSION=`cat $SYSTEM_ARTIFACTSDIRECTORY/metadata/version`

export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -g azure-cli-prod -n azurecliprod -otsv)
TAR_NAME=azure-cli-$CLI_VERSION.tar.gz

if [ ! -d ./archive/pypi ]; then
    az storage blob download-batch -s $RELEASE_CONTAINER_NAME -d ./artifacts --pattern 'pypi/*'
fi

mkdir -p $BUILD_STAGINGDIRECTORY/github/ >/dev/null 2>&1
mkdir -p $BUILD_STAGINGDIRECTORY/homebrew/ >/dev/null 2>&1
curl -sL https://github.com/Azure/azure-cli/archive/$TAR_NAME -o $BUILD_STAGINGDIRECTORY/github/$TAR_NAME

echo "Upload Azure CLI Source Package"
az storage blob upload -c releases -n $TAR_NAME -f $BUILD_STAGINGDIRECTORY/github/$TAR_NAME --no-progress -ojson

HOMEBREW_UPSTREAM_URL=$(az storage blob url -c releases -n $TAR_NAME -otsv)
curl -sfS -I $HOMEBREW_UPSTREAM_URL >/dev/null

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

docker cp $container_name:azure-cli.rb ./artifacts/homebrew/azure-cli.rb
docker rm $container_name