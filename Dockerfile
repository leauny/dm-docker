# install stage
FROM ubuntu:latest as install

ARG DM_INSTALL_USER=ubuntu
ARG DM_INSTALL_GROUP=ubuntu
ARG DM_BIN=./res/dm.bin
ARG DM_INSTALL_CONFIG=./res/install.xml
ARG USELESS_DIR="./doc ./include ./drivers ./uninstall ./samples ./desktop"

COPY ${DM_INSTALL_CONFIG} /home/install.xml
COPY ${DM_BIN} /home/dm.bin

RUN groupadd -f ${DM_INSTALL_GROUP} && \
    if [ ! "$(getent passwd ${DM_INSTALL_USER})" ]; then \
        useradd -g ${DM_INSTALL_GROUP} -ms /bin/bash ${DM_INSTALL_USER} 2>/dev/null; \
    fi && \
    mkdir -p /dm8/data && chown ${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8 && \
    chown ${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8/data && chmod -R 755 /dm8 && \
    chmod +x /home/dm.bin && \
    su ${DM_INSTALL_USER} -c "/home/dm.bin -q /home/install.xml" && \
    cd /dm8/dmdbms && rm -rf ${USELESS_DIR}

# deploy stage
FROM ubuntu:latest

ARG DM_INSTALL_USER=ubuntu
ARG DM_INSTALL_GROUP=ubuntu

RUN groupadd -f ${DM_INSTALL_GROUP} && \
    if [ ! "$(getent passwd ${DM_INSTALL_USER})" ]; then \
        useradd -g ${DM_INSTALL_GROUP} -ms /bin/bash ${DM_INSTALL_USER} 2>/dev/null; \
    fi && \
    echo 'root:dbmsdbms' | chpasswd && \
    # change /dm8 owner
    mkdir /dm8 && chown ${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8 && \
    # config limits
    echo "${DM_INSTALL_USER} hard nofile 65536\n"\
         "${DM_INSTALL_USER} soft nofile 65536\n"\
         "${DM_INSTALL_USER} hard stack 32768\n"\
         "${DM_INSTALL_USER} soft stack 16384" >> /etc/security/limits.conf && \
    # /etc/profile
    echo 'export DM_HOME="/dm8/dmdbms"\n'\
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n'\
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /etc/profile && \
    # root bashrc
    echo 'export DM_HOME="/dm8/dmdbms"\n'\
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n'\
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /root/.bashrc && \
    # DM_INSTALL_USER bashrc
    echo 'export DM_HOME="/dm8/dmdbms"'\
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n'\
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /home/${DM_INSTALL_USER}/.bashrc

RUN apt-get update && \
    apt-get install -y sudo nftables && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* &&\
    echo "${DM_INSTALL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${DM_INSTALL_USER}

COPY --from=install --chown=${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8 /dm8

WORKDIR /dm8

ENV DM_HOME="/dm8/dmdbms"
ENV PATH="$PATH:$DM_HOME/bin:$DM_HOME/tool"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$DM_HOME/bin"

CMD dminit PATH=/dm8/data/init && dmserver /dm8/data/init/DAMENG/dm.ini
