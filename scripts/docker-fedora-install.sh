#! /bin/bash
#
# Remove existing installation
#
sudo dnf remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

# Add docker repository
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
  --add-repo \
  https://download.docker.com/linux/fedora/docker-ce.repo

# Install docker and related
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start docker
sudo systemctl start docker

# Test docker
sudo docker run hello-world
