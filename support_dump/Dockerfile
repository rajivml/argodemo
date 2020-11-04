# Same base image as deployer and trainer
FROM uipath/ubuntu-k8s:0.1


#COPY s3cmd-2.0.2 /s3cmd-2.0.2
#RUN chmod u+x /s3cmd-2.0.2/s3cmd


RUN apt-get update -y && \
    apt-get install -y s3cmd && \
    apt-get install zip -y && \
    apt-get install -y bc && \
    mkdir -p /scripts && \
    mkdir -p /aifabric/support_bundle

COPY scripts/ scripts/
COPY support_bundle.sh support_bundle.sh

ENTRYPOINT ["bash", "support_bundle.sh"]

