#!/bin/bash

echo "Starting support-dump build ... "

tag=argocd
find . -type f -print0 | xargs -0 dos2unix

docker build -f ./Dockerfile -t gcr.io/dave-225414/on-prem/support-dump:$tag .


