# 仮想化するベースOS
FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y

ARG USERNAME=apto-as
ARG GROUPNAME=apto-as
ARG UID=1000
ARG GID=1000
ARG PASSWORD=kamuinomi333
RUN groupadd -g $GID $GROUPNAME && \
    useradd -m -s /bin/bash -u $UID -g $GID -G sudo $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/