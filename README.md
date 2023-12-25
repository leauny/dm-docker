# DM-Docker

> 项目用于构建DM-DBMS的Docker镜像

## Usage

> 默认镜像tag为dm8, 且被docker-compose依赖
> 默认只安装server, 且删除部分无用文件夹(见 `res/install.xml`)

1. 克隆仓库并进入文件夹
2. 修改 `res/install.xml` 下的安装配置信息(Warn: 不要修改任何有关目录的配置)
3. 运行 `build.sh` 并传入 `DMInstall.bin` 路径以及 `res/install.xml` 或修改好的安装配置信息
4. 执行 `docker compose up -d` 运行镜像(可按需修改配置)

