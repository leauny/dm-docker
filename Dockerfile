# install stage
FROM ubuntu:jammy-20240911.1 AS install

ARG DM_INSTALL_USER=ubuntu
ARG DM_INSTALL_GROUP=ubuntu

RUN groupadd -f ${DM_INSTALL_GROUP} && \
    if [ ! "$(getent passwd ${DM_INSTALL_USER})" ]; then \
        useradd -g ${DM_INSTALL_GROUP} -ms /bin/bash ${DM_INSTALL_USER} 2>/dev/null; \
    fi && \
    mkdir /dm8 && chown ${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8

USER ${DM_INSTALL_USER}

ARG DM_BIN=./res/dm.bin
ARG DM_INSTALL_CONFIG=./res/install.xml
ARG USELESS_DIR="./doc ./include ./drivers ./uninstall ./samples ./desktop"

COPY ${DM_INSTALL_CONFIG} /home/${DM_INSTALL_USER}/install.xml
COPY ${DM_BIN} /home/${DM_INSTALL_USER}/dm.bin

RUN mkdir -p /dm8/data && \
#chmod +x /home/${DM_INSTALL_USER}/dm.bin && \
    /home/${DM_INSTALL_USER}/dm.bin -q /home/${DM_INSTALL_USER}/install.xml && \
    cd /dm8/dmdbms && rm -rf ${USELESS_DIR}

# deploy stage
FROM ubuntu:jammy-20240911.1

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

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

USER ${DM_INSTALL_USER}

COPY --from=install --chown=${DM_INSTALL_USER}:${DM_INSTALL_GROUP} /dm8 /dm8

WORKDIR /dm8

ENV DM_HOME="/dm8/dmdbms"
ENV PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool
ENV LD_LIBRARY_PATH="$DM_HOME/bin"

CMD ["/usr/bin/bash", "-c", "dminit PATH=/dm8/data/init && dmserver /dm8/data/init/DAMENG/dm.ini"]
