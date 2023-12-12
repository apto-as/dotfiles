FROM almalinux:8

RUN dnf install sudo epel-release -y
RUN dnf update

ARG USERNAME=apto-as
ARG PASSWORD=kamuinomi333
RUN useradd -m $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/