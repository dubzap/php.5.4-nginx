FROM php:5.4-fpm
LABEL maintainer="dubzap@gmail.com"

# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        libbz2-dev \
        libmemcached-dev \
        libmysqlclient-dev \
        libsasl2-dev \
    " \
    runtimeDeps=" \
        curl \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmcrypt-dev \
        libmemcachedutil2 \
        libpng12-dev \
        libpq-dev \
        libxml2-dev \
        libxslt1-dev \
    " \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps \
    && docker-php-ext-install bcmath bz2 calendar iconv intl mbstring mcrypt mysql mysqli pdo_mysql pdo_pgsql pgsql soap xsl zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-install exif \
    && pecl install memcached-2.2.0 redis-4.3.0 zendopcache \
    && docker-php-ext-enable memcached.so redis.so opcache.so \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -r /var/lib/apt/lists/*

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1
# Install NGINX
RUN     \
#       BUILD_DEPS='software-properties-common python-software-properties wget nano mc' \
        apt-get update \
        && apt-get install --no-install-recommends -y wget nano mc \
        && wget -O - http://nginx.org/keys/nginx_signing.key | apt-key add - \
        && echo "deb http://nginx.org/packages/ubuntu/ precise nginx" | tee -a /etc/apt/sources.list \
        && echo "deb-src http://nginx.org/packages/ubuntu/ precise nginx" | tee -a /etc/apt/sources.list \
        && apt-get update \
        && apt-get install -y nginx \
        # Cleaning
        && apt-get purge -y --auto-remove ${BUILD_DEPS} \
        && apt-get autoremove -y && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        # Forward request and error logs to docker log collector
        && ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log
WORKDIR /var/www/

EXPOSE 80 443
