# install stage
FROM ubuntu:latest as install

ARG DM_BIN=./res/dm.bin
ARG DM_INSTALL_CONFIG=./res/install.xml
ARG USELESS_DIR="./doc ./include ./drivers ./uninstall ./samples ./desktop"

COPY ${DM_INSTALL_CONFIG} /home/install.xml
COPY ${DM_BIN} /home/dm.bin

RUN groupadd dinstall && \
    useradd -g dinstall -ms /bin/bash dmdba && \
    mkdir /dm8 && chown dmdba:dinstall /dm8 && chmod -R 755 /dm8 && \
    chmod +x /home/dm.bin && \
    su dmdba -c "/home/dm.bin -q /home/install.xml" && \
    cd /dm8/dmdbms && rm -rf ${USELESS_DIR}

# deploy stage
FROM ubuntu:latest

RUN groupadd dinstall && \
    useradd -g dinstall -ms /bin/bash dmdba && \
    echo 'dmdba:dbmsdba' | chpasswd && \ 
    echo 'root:dbmsdbms' | chpasswd && \
    # change /dm8 owner
    mkdir /dm8 && chown dmdba:dinstall /dm8 && \
    # config limits
    echo 'dmdba hard nofile 65536\n' \
         'dmdba soft nofile 65536\n' \
         'dmdba hard stack 32768\n' \
         'dmdba soft stack 16384' >> /etc/security/limits.conf && \
    # /etc/profile
    echo 'export DM_HOME="/dm8/dmdbms"\n' \
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n' \
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /etc/profile && \
    # root bashrc
    echo 'export DM_HOME="/dm8/dmdbms"\n' \
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n' \
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /root/.bashrc && \
    # dmdba bashrc
    echo 'export DM_HOME="/dm8/dmdbms"\n' \
         'export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool\n' \
         'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin' >> /home/dmdba/.bashrc

USER dmdba

COPY --from=install /dm8 /dm8

WORKDIR /dm8

CMD echo "init env variables ..." && \
    export DM_HOME="/dm8/dmdbms" && \
    export PATH=$PATH:$DM_HOME/bin:$DM_HOME/tool && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DM_HOME/bin && \
    echo "init database ..." && \
    dminit PATH=/dm8/data/init && \
    echo "start dm server ..." && \
    dmserver /dm8/data/init/DAMENG/dm.ini
