FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-json \
    php-ldap \
    php-xml \
    php-mbstring \
    nodejs \
    npm \
    wget \
    git \
    curl \
    libnewt-dev \
    libssl-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libjansson-dev \
    uuid-dev \
    subversion \
    libxml2-dev \
    libsrtp2-dev \
    && rm -rf /var/lib/apt/lists/*

# Create asterisk user first
RUN useradd -m asterisk

# Install Asterisk
WORKDIR /usr/src
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20.5.0.tar.gz && \
    tar xvf asterisk-20.5.0.tar.gz && \
    cd asterisk-20.5.0 && \
    ./configure --with-jansson-bundled && \
    make menuselect.makeopts && \
    ./menuselect/menuselect \
        --disable BUILD_NATIVE \
        --enable CORE-SOUNDS-EN-GSM \
        --enable MOH-OPSOUND-GSM && \
    make && \
    make install && \
    make samples && \
    make config && \
    ldconfig

# Set correct permissions
RUN chown -R asterisk:asterisk /var/lib/asterisk && \
    chown -R asterisk:asterisk /var/spool/asterisk && \
    chown -R asterisk:asterisk /var/run/asterisk && \
    chown -R asterisk:asterisk /var/log/asterisk && \
    chown -R asterisk:asterisk /usr/lib/asterisk && \
    chown -R asterisk:asterisk /etc/asterisk

# Install FreePBX
WORKDIR /usr/src
RUN wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz && \
    tar xfz freepbx-16.0-latest.tgz && \
    cd freepbx && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    ./install --nodatabase --force

# Setup MySQL
RUN service mariadb start && \
    mysql -e "CREATE DATABASE asterisk;" && \
    mysql -e "GRANT ALL PRIVILEGES ON asterisk.* TO asterisk@localhost IDENTIFIED BY 'asteriskpassword';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Create start script
RUN echo '#!/bin/bash\n\
service mariadb start\n\
service apache2 start\n\
runuser -l asterisk -c "asterisk -f"' > /start.sh && \
    chmod +x /start.sh

EXPOSE 80 443 5060/udp 5060/tcp 10000-20000/udp

CMD ["/start.sh"]