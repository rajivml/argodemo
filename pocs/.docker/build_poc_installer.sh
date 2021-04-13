find ../../pocs/ -type f -name '*.sh' -print0 | xargs -0 chmod +x
podman build --format=docker -f ./DockerFabricInstaller -t uipath/fabric-installer:0.1 .
