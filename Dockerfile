#############################
#     设置公共的变量         #
#############################
FROM ubuntu:latest AS base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/php
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=ubuntu
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=latest
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# ##############################################################################

# ***** 设置变量 *****

# 工作目录
ARG PHP_DIR=/data/php
ENV PHP_DIR=$PHP_DIR
# 环境变量
ARG PATH=/data/php/bin:$PATH
ENV PATH=$PATH
# 源文件下载路径
ARG DOWNLOAD_SRC=/tmp/src
ENV DOWNLOAD_SRC=$DOWNLOAD_SRC

# PHP版本
# https://github.com/php
ARG PHP_VERSION=8.3.3
ENV PHP_VERSION=$PHP_VERSION
# PHP编译参数
ARG PHP_BUILD_CONFIG="\
    --prefix=${PHP_DIR} \
    --with-config-file-path=${PHP_DIR}/etc \
    --with-fpm-user=nginx  \
    --with-fpm-group=nginx \
    --with-curl \
    --with-freetype \
    --enable-gd \
    --with-gettext \
    --with-kerberos \
    --with-libxml \
    --with-pgsql \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-openssl \
    --with-external-pcre \
    --with-pdo-sqlite \
    --with-pear \
    --with-xsl \
    --with-zlib \
    --with-jpeg \
    --with-mhash \
    --with-sqlite3 \
    --with-bz2 \
    --with-cdb \
    --with-gmp \
    --with-readline \
    --with-ldap \
    --with-tidy \
    --with-imap \
    --with-imap-ssl \
    --with-imap-ssl \
    --with-zlib-dir \
    --without-pdo-sqlite \
    --with-libxml \
    --with-zip \
    --enable-fpm \
    --enable-cgi \
    --enable-bcmath \
    --enable-mysqlnd-compression-support \
    --enable-mbregex \
    --enable-mbstring \
    --enable-opcache \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvsem \
    --enable-xml \
    --enable-session \
    --enable-ftp \
    --enable-shared  \
    --enable-calendar \
    --enable-dom \
    --enable-exif \
    --enable-fileinfo \
    --enable-filter \
    --enable-pdo \
    --enable-simplexml \
    --enable-sysvmsg \
    --enable-sysvshm \
    --enable-cli \
    --enable-ctype \
    --enable-posix \
    --enable-opcache \
    --enable-tokenizer \
    --enable-dba \
    --enable-xmlreader \
    --enable-xmlwriter \
    --enable-intl \
    --enable-libgcc \
"
ENV PHP_BUILD_CONFIG=$PHP_BUILD_CONFIG

# 扩展插件版本
# redis
# https://pecl.php.net/package/redis
ARG REDIS_VERSION=6.0.2
ENV REDIS_VERSION=$REDIS_VERSION
# swoole
# https://pecl.php.net/package/swoole
ARG SWOOLE_VERSION=5.1.1
ENV SWOOLE_VERSION=$SWOOLE_VERSION
# mongodb
# https://pecl.php.net/package/mongodb
ARG MONGODB_VERSION=1.17.2
ENV MONGODB_VERSION=$MONGODB_VERSION

# 构建阶段依赖软件包
ARG BUILD_DEPS="\
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libxml2-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libgettextpo-dev \
    libiconv-hook-dev \
    libkrb5-dev \
    libxml2-dev \
    libpq-dev \
    libmysqlclient-dev \
    libssl-dev \
    libpcre3-dev \
    libpcre2-dev \
    libpcre2-8-0 \
    libsqlite3-dev \
    libbz2-dev \
    libcdb-dev \
    libgmp-dev \
    libreadline-dev \
    libldap2-dev \
    libtidy-dev \
    libzip-dev \
    libonig-dev \
    libonig5 \
    libc-client-dev \
    libgpgme11-dev \
    libmecab-dev \
    libicu-dev \
    libxslt1-dev \
    bison \
    re2c \
    wget \
    debsums \
    locales \
    iptables \
    python3 \
    python3-dev \
    python3-pip \
    language-pack-zh-hans \
    fonts-droid-fallback \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    ca-certificates"
ENV BUILD_DEPS=$BUILD_DEPS

# PHP相关依赖包
ARG PHP_BUILD_DEPS="\
    libxml2 \
    libcurl4 \
    libfreetype6 \
    libjpeg-dev \
    libpng16-16 \
    libgettextpo0 \
    libiconv-hook1 \
    libkrb5-3 \
    libpq5 \
    libmysqlclient21 \
    libssl-dev \
    libpcre3 \
    libpcre2-8-0 \
    libsqlite3-0 \
    libbz2-1.0 \
    libcdb1 \
    libgmp10 \
    libreadline8 \
    libldap2-dev \
    libtidy-dev \
    libzip4 \
    libonig5 \
    libxslt1-dev \
    libc-client-dev \
    libgpgme11 \
    libmecab2 \
    libc-client2007e \
    libmcrypt4 \
    libltdl7 \
    libwebp-dev"
ENV PHP_BUILD_DEPS=$PHP_BUILD_DEPS

####################################
#       构建二进制文件             #
####################################
FROM base AS builder


# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i s@http://*.*ubuntu.com@https://mirrors.aliyun.com@g /etc/apt/sources.list && \
   sed -i 's?# deb-src?deb-src?g' /etc/apt/sources.list && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends $BUILD_DEPS $PHP_BUILD_DEPS && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 创建相关目录
   mkdir -pv ${DOWNLOAD_SRC} ${PHP_DIR}
   

# ##############################################################################
# ***** 下载源码包 *****  
RUN set -eux && \
    wget --no-check-certificate https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.tar.gz \
    -O ${DOWNLOAD_SRC}/php-${PHP_VERSION}.tar.gz && \
    wget --no-check-certificate https://pecl.php.net/get/redis-${REDIS_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/redis-${REDIS_VERSION}.tgz && \
    wget --no-check-certificate https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/swoole-${SWOOLE_VERSION}.tgz && \
    wget --no-check-certificate https://pecl.php.net/get/mongodb-${MONGODB_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/mongodb-${MONGODB_VERSION}.tgz && \
    cd ${DOWNLOAD_SRC} && tar xvf php-${PHP_VERSION}.tar.gz -C ${DOWNLOAD_SRC} && \
    tar zxf redis-${REDIS_VERSION}.tgz -C ${DOWNLOAD_SRC} && \
    tar zxf swoole-${SWOOLE_VERSION}.tgz -C ${DOWNLOAD_SRC} && \
    tar zxf mongodb-${MONGODB_VERSION}.tgz -C ${DOWNLOAD_SRC}

# ***** 安装PHP *****
RUN set -eux && \
    cd ${DOWNLOAD_SRC}/php-src-php-${PHP_VERSION} && \
    ./buildconf --force && \
    ./configure ${PHP_BUILD_CONFIG} && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    ln -sf ${PHP_DIR}/bin/* /usr/bin/ && \
    ln -sf ${PHP_DIR}/sbin/* /usr/sbin/ && \
    cd ${DOWNLOAD_SRC}/redis-${REDIS_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    cd ${DOWNLOAD_SRC}/swoole-${SWOOLE_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    cd ${DOWNLOAD_SRC}/mongodb-${MONGODB_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install

##########################################
#         构建最新的镜像                  #
##########################################
FROM base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG


# 安装依赖包
ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    dnsutils \
    iproute2 \
    net-tools \
    sysstat \
    ncat \
    git \
    vim \
    jq \
    lrzsz \
    tzdata \
    curl \
    wget \
    axel \
    lsof \
    zip \
    unzip \
    tar \
    rsync \
    iputils-ping \
    telnet \
    procps \
    libaio1 \
    numactl \
    xz-utils \
    gnupg2 \
    psmisc \
    libmecab2 \
    debsums \
    locales \
    iptables \
    python3 \
    python3-dev \
    python3-pip \
    language-pack-zh-hans \
    fonts-droid-fallback \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# PHP相关依赖包
ARG PHP_BUILD_DEPS="\
    libxml2 \
    libcurl4 \
    libfreetype6 \
    libjpeg-dev \
    libpng16-16 \
    libgettextpo0 \
    libiconv-hook1 \
    libkrb5-3 \
    libpq5 \
    libmysqlclient21 \
    libssl-dev \
    libpcre3 \
    libpcre2-8-0 \
    libsqlite3-0 \
    libbz2-1.0 \
    libcdb1 \
    libgmp10 \
    libreadline8 \
    libldap2-dev \
    libtidy-dev \
    libzip4 \
    libonig5 \
    libxslt1-dev \
    libc-client-dev \
    libgpgme11 \
    libmecab2 \
    libc-client2007e \
    libmcrypt4 \
    libltdl7 \
    libwebp-dev"
ENV PHP_BUILD_DEPS=$PHP_BUILD_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i s@http://*.*ubuntu.com@https://mirrors.aliyun.com@g /etc/apt/sources.list && \
   sed -i 's?# deb-src?deb-src?g' /etc/apt/sources.list && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends $PKG_DEPS $PHP_BUILD_DEPS && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   locale-gen zh_CN.UTF-8 && localedef -f UTF-8 -i zh_CN zh_CN.UTF-8 && locale-gen && \
   /bin/zsh

# 拷贝文件
COPY --from=builder /data /data

# ***** 容器信号处理 *****
STOPSIGNAL SIGQUIT

# ***** 监听端口 *****
EXPOSE 9000/TCP

# ***** 工作目录 *****
WORKDIR /data/php

# ***** 创建用户和用户组 *****
RUN set -eux && \
    # 创建用户和用户组
    addgroup --system --quiet nginx && \
    adduser --quiet --system --disabled-login --ingroup nginx --home /data/nginx --no-create-home nginx && \
    cp -rf /root/.oh-my-zsh ${PHP_DIR}/.oh-my-zsh && \
    cp -rf /root/.zshrc ${PHP_DIR}/.zshrc && \
    sed -i '5s#/root/.oh-my-zsh#${PHP_DIR}/.oh-my-zsh#' ${PHP_DIR}/.zshrc && \
    chmod -R 775 ${PHP_DIR} && \
    mkdir -pv ${PHP_DIR}/etc/php-fpm.d/ ${PHP_DIR}/var/run/ ${PHP_DIR}/var/log/ && \
    ln -sf ${PHP_DIR}/bin/* /usr/bin/ && \
    ln -sf ${PHP_DIR}/sbin/* /usr/sbin/
    
# 拷贝文件
COPY ["./conf/php/etc/php.ini", "/data/php/etc/php.ini"]
COPY ["./conf/php/etc/php-fpm.conf", "/data/php/etc/php-fpm.conf"]
COPY ["./conf/php/etc/php-fpm.d/www.conf", "/data/php/etc/php-fpm.d/www.conf"]

# 启动命令
CMD ["php-fpm", "--nodaemonize", "--fpm-config", "/data/php/etc/php-fpm.conf"]
