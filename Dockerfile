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
    && rm -rf /var/lib/apt/lists/*

# Install Asterisk (previous Asterisk installation steps here)

# Install FreePBX
WORKDIR /usr/src
RUN wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz && \
    tar xfz freepbx-16.0-latest.tgz && \
    cd freepbx && \
    ./start_asterisk start && \
    ./install -n

# Configure Apache for FreePBX
COPY freepbx.conf /etc/apache2/sites-available/
RUN a2ensite freepbx && \
    a2enmod rewrite

# Expose additional ports for web interface
EXPOSE 80 443

# Start services
COPY start.sh /
RUN chmod +x /start.sh
CMD ["/start.sh"]