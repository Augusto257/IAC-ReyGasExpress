FROM jenkins/inbound-agent:latest

USER root

RUN apt-get update && \
    apt-get install -y unzip curl && \
    curl -sLo terraform.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip && \
    terraform -version && \
    apt-get clean

USER jenkins
