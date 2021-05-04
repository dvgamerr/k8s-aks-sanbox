FROM centos:8
LABEL maintainer="Kananek Thongkam"

RUN useradd -ms /bin/bash daemon

USER daemon
WORKDIR /tmp

RUN yum upgrade -y && \
    yum install jq -y

# Installation azure-cli
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    echo -e "[azure-cli]\n\
name=Azure CLI\n\
baseurl=https://packages.microsoft.com/yumrepos/azure-cli\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/azure-cli.repo && \
    dnf install azure-cli

# Installation kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Installation helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

WORKDIR /workbranch

COPY entrypoint.sh .

RUN rm -Rf /tmp

ENTRYPOINT [ "./entrypoint.sh" ]
