FROM ubuntu:latest as file
MAINTAINER leauny leauny@outlook.com

COPY install /home
COPY dm.bin /home

RUN apt-get update && \
    apt-get install -y iputils-ping net-tools tmux less nano && \
    apt-get clean && \
    groupadd dinstall && \
    useradd -g dinstall -ms /bin/bash dmdba && \
    echo 'dmdba:dbmsdba' | chpasswd && \ 
    echo 'root:dbmsdbms' | chpasswd && \
    echo 'dmdba hard nofile 65536' >> /etc/security/limits.conf && \
    echo 'dmdba soft nofile 65536' >> /etc/security/limits.conf && \
    echo 'dmdba hard stack 32768' >> /etc/security/limits.conf && \
    echo 'dmdba soft stack 16384' >> /etc/security/limits.conf && \
    mkdir /dm8 && \
    chmod -R 755 /dm8 && \
    chown dmdba:dinstall -R /dm8 && \ 
    chown dmdba:dinstall -R /home/dmdba && \
    chmod +x /home/dm.bin && \
    su dmdba && \
    cat /home/install | /home/dm.bin -i && \ 
    echo 'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool' >> /home/dmdba/.bash_profile  && \
    echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/dm8/bin"' >> /home/dmdba/.bashrc  && \
    echo 'export DM_HOME="/dm8"' >> /home/dmdba/.bashrc  && \
    echo 'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool' >> /home/dmdba/.bashrc  && \
    rm /home/dm.bin /home/install

WORKDIR /dm8

ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/dm8/bin" \
    DM_HOME="/dm8" \ 
    PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool

CMD ["tmux"]
