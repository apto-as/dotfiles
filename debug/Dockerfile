# 仮想化するベースOS
FROM ubuntu:latest

ENV USER timoto 
ENV HOME /home/${USER}
ENV SHELL /bin/bash

# 一般ユーザーアカウントを追加
RUN useradd -m ${USER}
# 一般ユーザーにsudo権限を付与
RUN gpasswd -a ${USER} sudo
# 一般ユーザーのパスワード設定
RUN echo "${USER}:timoto" | chpasswd

# SUDOコマンドのインストール
RUN apt-get update
RUN apt-get install -y sudo

# 以降のRUN/CMDを実行するユーザー
USER ${USER}
# 以降の作業ディレクトリを指定
WORKDIR ${HOME}
