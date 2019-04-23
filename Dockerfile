#
# The Application Core Container
#

# Pull base image
FROM webdevops/base:ubuntu-18.04

MAINTAINER Chibuzor Ogbu <chibuzorogbu@gmail.com>

COPY artifacts .
COPY conf/ /opt/docker

ARG PHALCON_BUILD
ARG PHP_VERSION

ENV PATH=/root/composer/vendor/bin:$PATH \
    COMPOSER_HOME=/root/composer \
    COMPOSER_ALLOW_SUPERUSER=1 \
    APPLICATION_PATH="/project" \
    APPLICATION_USER="www-data" \
    APPLICATION_GROUP="www-data" \
    DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=$PHP_VERSION \
    XDEBUG_IDEKEY="PHPSTORM" \
    XDEBUG_SHOW_LOCAL_VARS=1 \
    XDEBUG_SCREAM=0 \
    XDEBUG_SHOW_ERROR_TRACE=1 \
    XDEBUG_REMOTE_PORT=9000 \
    XDEBUG_REMOTE_CONNECT_BACK=0 \
    XDEBUG_REMOTE_AUTOSTART=1 \
    XDEBUG_REMOTE_ENABLE=1 \
    XDEBUG_REMOTE_HOST=0.0.0.0

RUN echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

RUN apt update -y --no-install-recommends

RUN mkdir -p $APPLICATION_PATH/public \
    && chown -R $APPLICATION_USER:$APPLICATION_GROUP $APPLICATION_PATH \
    && curl -s https://packagecloud.io/install/repositories/phalcon/$PHALCON_BUILD/script.deb.sh | bash \
    && apt install -y --no-install-recommends software-properties-common snmp snmp-mibs-downloader \
    && LANG=C.UTF-8 apt-add-repository -y ppa:ondrej/php \
    && echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && apt update -y

RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ bionic nginx" | tee -a /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" | tee -a /etc/apt/sources.list \
    && wget -qO - https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && apt update -y \
    && apt install -y nginx nano

RUN apt update -y  \
	&& apt install -y git git-flow

# Deploy node
RUN apt purge -y nodejs npm \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt install -y nodejs \
    && npm install npm --global


RUN apt -o Dpkg::Options::="--force-confnew" install -y -f --no-install-recommends \
        php$PHP_VERSION \
        php$PHP_VERSION-cli \
        php$PHP_VERSION-bcmath \
        php-apcu \
        pwgen \
        php$PHP_VERSION-bz2 \
        php$PHP_VERSION-dev \
        php$PHP_VERSION-dba \
        php$PHP_VERSION-gmp \
        php$PHP_VERSION-gd \
        php$PHP_VERSION-imap \
        php$PHP_VERSION-mysql \
        php$PHP_VERSION-json \
        php$PHP_VERSION-intl \
        php$PHP_VERSION-curl \
        php$PHP_VERSION-common \
        php$PHP_VERSION-ldap \
        php$PHP_VERSION-opcache \
        php$PHP_VERSION-mbstring \
        php$PHP_VERSION-mongodb \
        php$PHP_VERSION-msgpack \
        php-pear \
        php$PHP_VERSION-odbc \
        php$PHP_VERSION-pgsql \
        php$PHP_VERSION-pspell \
        php$PHP_VERSION-readline \
        php$PHP_VERSION-snmp \
        php$PHP_VERSION-soap \
        php$PHP_VERSION-xml \
        php$PHP_VERSION-xmlrpc \
        php$PHP_VERSION-xsl \
        php$PHP_VERSION-zip \
        php$PHP_VERSION-recode \
        php-ssh2 \
        php$PHP_VERSION-tidy \
        php$PHP_VERSION-fpm \
        php$PHP_VERSION-phalcon \
        php-yaml \
        lsb-release \
        libpcre3-dev \
        libssh2-1-dev \
        libyaml-dev \
        libssl-dev


RUN wget -O phive.phar https://phar.io/releases/phive.phar \
    && wget -O phive.phar.asc https://phar.io/releases/phive.phar.asc \
    && gpg --keyserver hkps.pool.sks-keyservers.net --recv-keys 0x9D8A98B29B2D5D79 \
    && gpg --verify phive.phar.asc phive.phar \
    && chmod +x phive.phar \
    && mv phive.phar /usr/bin/phive

RUN cp -R /artifacts/etc/php/$PHP_VERSION/mods-available /etc/php/$PHP_VERSION/mods-available \
    && cp -R /artifacts/usr/lib/php/`php-config --phpapi` /usr/lib/php/`php-config --phpapi` \
    && touch /var/run/php/php$PHP_VERSION-fpm.sock \
    && chown -R $APPLICATION_USER:$APPLICATION_GROUP /var/run/php \
    && FILES=/artifacts/etc/php/$PHP_VERSION/mods-available/* && for f in $FILES; \
            do \
                phpenmod -v $PHP_VERSION -s ALL `basename $f | cut -d '.' -f 1`; \
            done \
    && php -m

RUN pecl channel-update pecl.php.net \
    && curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x phpcs.phar \
    && mv phpcs.phar /usr/local/bin/phpcs \
    && curl -sOL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/phpcbf \
    && curl -sOL http://static.phpmd.org/php/latest/phpmd.phar \
    && chmod +x phpmd.phar \
    && mv phpmd.phar /usr/local/bin/phpmd \
    && curl -sOL http://www.phing.info/get/phing-latest.phar \
    && chmod +x phing-latest.phar \
    && mv phing-latest.phar /usr/local/bin/phing \
    && mkdir $COMPOSER_HOME \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

RUN pear config-set preferred_state beta \
	&& apt install -y --reinstall build-essential \
	&& pecl install xdebug

RUN TIMEZONE=`cat /etc/timezone`; sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/$PHP_VERSION/cli/php.ini \
    && TIMEZONE=`cat /etc/timezone`; sed -i "s|;date.timezone =.*|date.timezone = ${TIMEZONE}|" /etc/php/$PHP_VERSION/fpm/php.ini \
    && sed -i "s|memory_limit =.*|memory_limit = -1|" /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i 's|short_open_tag =.*|short_open_tag = On|' /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i 's|error_reporting =.*|error_reporting = -1|' /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i 's|display_errors =.*|display_errors = On|' /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i 's|display_startup_errors =.*|display_startup_errors = On|' /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i -re 's|^(;?)(session.save_path) =.*|\2 = "/tmp"|g' /etc/php/$PHP_VERSION/cli/php.ini \
    && sed -i -re 's|^(;?)(phar.readonly) =.*|\2 = off|g' /etc/php/$PHP_VERSION/cli/php.ini \
    && echo "apc.enable_cli = 1" >> /etc/php/$PHP_VERSION/mods-available/apcu.ini \
    && echo "zend_extension=xdebug.so" >> /etc/php/$PHP_VERSION/cli/php.ini

# add build script (also set timezone to AFRICA/LAGOS)

COPY conf/provision/bootstrap.d/*.sh /opt/docker/provision/bootstrap.d/
COPY conf/provision/entrypoint.d/*.sh /opt/docker/provision/entrypoint.d/
ADD conf/provision/bootstrap.d/.bashrc /opt/docker/provision/entrypoint.d/.bashrc
RUN chmod +x /opt/docker/provision/bootstrap.d/*.sh \
    && chmod +x /opt/docker/provision/entrypoint.d/*.sh

# copy files from repo
COPY conf/nginx/main/http.conf /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
	&& echo "user ${APPLICATION_USER} ${APPLICATION_GROUP};" >> /etc/nginx/nginx.conf \
	&& rm -f    /etc/nginx/conf.d/default.conf \
ADD app/index.php $APPLICATION_PATH/public/index.php

RUN apt autoremove -y \
    && apt autoclean -y \
    && apt clean -y \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /artifacts \
        /opt/docker/etc/php/fpm/pool.d/www.conf

# Define mountable directories.
COPY conf/nginx/conf.d/*.conf /etc/nginx/conf.d/
COPY conf/nginx/certs /etc/nginx/certs
COPY conf/nginx/sites-enabled/*.conf /etc/nginx/sites-enabled/
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]


RUN /opt/docker/bin/bootstrap.sh
EXPOSE 80 443 9000

# Define default command
CMD /etc/init.d/php$PHP_VERSION-fpm restart && nginx