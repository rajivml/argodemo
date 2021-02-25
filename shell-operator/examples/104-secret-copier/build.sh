#**** DockerBuild on windows is screwing up permissions, but the build from linux is working fine, copy the zip file committed here to linux machine and build the same from there
#find . -type f -print0 | xargs -0 dos2unix
docker build -f ./Dockerfile -t uipath/secret-copier:0.1 .
