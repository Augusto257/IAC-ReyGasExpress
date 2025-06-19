FROM jenkins/jenkins:lts

USER root

# Instalamos dependencias necesarias (como unzip, curl, terraform si quieres dejarlo ya listo)
RUN apt-get update && \
    apt-get install -y unzip curl && \
    rm -rf /var/lib/apt/lists/*

# Instala Terraform (opcional)
ARG TERRAFORM_VERSION=1.6.6
RUN curl -sLo terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# Instalamos el CLI de Jenkins para plugins (ya viene en imagen moderna)
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
RUN chmod +x /usr/local/bin/install-plugins.sh && \
    install-plugins.sh

# Copiamos configuración de Jenkins como código (JCasC)
COPY jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml

# Creamos carpeta de casc si no existe y movemos el jenkins.yaml ahí
RUN mkdir -p /var/jenkins_home/casc && \
    cp /usr/share/jenkins/ref/jenkins.yaml /var/jenkins_home/casc/jenkins.yaml && \
    chown -R jenkins:jenkins /var/jenkins_home

USER jenkins
