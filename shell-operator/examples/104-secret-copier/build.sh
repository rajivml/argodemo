find . -type f -print0 | xargs -0 dos2unix
docker build -f ./Dockerfile -t uipath/secret-copier:0.1 .
