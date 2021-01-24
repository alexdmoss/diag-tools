FROM python:3.8.1-slim

RUN apt-get update && \
  apt-get --quiet --no-install-recommends --yes install \
  ca-certificates \
  curl \
  gettext-base \
  git \
  gnupg2 \
  jq \
  less \
  openssh-client \
  sudo \
  unzip \
  wget && \
  rm -rf /var/lib/apt/lists/*


# gcloud
ENV PATH=$PATH:/usr/local/google-cloud-sdk/bin
ARG GCLOUD_VERSION=324.0.0
RUN wget --no-verbose -O /tmp/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz && \
  tar -C /usr/local --keep-old-files -xz -f /tmp/google-cloud-sdk.tar.gz && \
  gcloud config set --installation component_manager/disable_update_check true && \
  gcloud config set --installation core/disable_usage_reporting true && \
  gcloud components install beta --quiet && \
  rm -f /tmp/google-cloud-sdk.tar.gz && \
  rm -rf /usr/local/google-cloud-sdk/.install/.backup && \
  find /usr/local/google-cloud-sdk -type d -name __pycache__ -exec rm -r {} \+

# kubectl
# checksum from changelog: https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.14.md#client-binaries
ARG KUBECTL_VERSION=1.19.2
ARG KUBECTL_SHA512="fe1aa1fa3d0c1a311d26159cb6b8acdc13d9201b647cc65b7bf2ac6e13400c07a0947fea479d1abd2da499809116dc64a1ee973ac33c81514d6d418f8bc6f5ac"
RUN wget --no-verbose -O /tmp/kubernetes-client.tar.gz https://dl.k8s.io/v${KUBECTL_VERSION}/kubernetes-client-linux-amd64.tar.gz && \
  echo "${KUBECTL_SHA512} /tmp/kubernetes-client.tar.gz" | sha512sum -c && \
  tar -C /usr/local/bin -xz -f /tmp/kubernetes-client.tar.gz --strip-components=3 kubernetes/client/bin/kubectl && \
  rm /tmp/kubernetes-client.tar.gz

# kustomize
# checksum from github release: https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv3.5.3
ARG KUSTOMIZE_VERSION=3.5.5
ARG KUSTOMIZE_SHA256="23306e0c0fb24f5a9fea4c3b794bef39211c580e4cbaee9e21b9891cb52e73e7"
RUN cd /usr/local/bin && \
  wget --no-verbose -O /tmp/kustomize.tar.gz "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" && \
  echo "${KUSTOMIZE_SHA256} /tmp/kustomize.tar.gz" | sha256sum -c && \
  tar -C /usr/local/bin -xz -f /tmp/kustomize.tar.gz && \
  rm /tmp/kustomize.tar.gz

# run as non-root but allow access to sudo if we need to add anything
RUN groupadd -g 1007 diag && useradd -u 1007 -g diag -G sudo -m -s /bin/bash diag
RUN sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    echo "diag ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER diag

CMD ["/bin/bash"]
