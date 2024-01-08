FROM almalinux:8

RUN dnf install sudo epel-release git -y
# install epel repo
RUN dnf config-manager --set-enabled powertools
RUN dnf install epel-release epel-next-release
RUN dnf install util-linux-user kernel-devel
RUN dnf group install -y "Development Tools"

# last update
RUN dnf update -y

ARG USERNAME=apto-as
ARG PASSWORD=kamuinomi333
RUN useradd -m $USERNAME && \
    echo $USERNAME:$PASSWORD | chpasswd && \
    echo "$USERNAME   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER $USERNAME
WORKDIR /home/$USERNAME/