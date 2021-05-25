FROM php:8.0.5-fpm

#############
# PHP SETUP #
#############

# copy config
COPY config/php/custom.ini /usr/local/etc/php/conf.d/


########################
# INSTALL DEPENDENCIES #
########################

# install persistent PHP extensions (they won't get purged afterwards)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --quiet --no-install-recommends \
        libfreetype6 xfonts-base xfonts-75dpi fonts-wqy-microhei ttf-wqy-microhei fonts-wqy-zenhei ttf-wqy-zenhei \
        ghostscript \
        supervisor \
        xmlstarlet \
        jpegoptim \
        pngquant \
        unzip \
        cron \
        wget \
        gdebi \
        git \
        default-mysql-client \
        sudo \
        nano \
    ; \
    pecl install -o -f redis \
    rm -rf /var/lib/apt/lists/*

# install PHP extensions
RUN set -ex; \
    \
    # mark packages as being manually installed
    # see https://manpages.debian.org/stretch/apt/apt-mark.8.en.html
    savedAptMark="$(apt-mark showmanual)"; \
    \
    # install via apt-get
    # see https://manpages.debian.org/stretch/apt/apt-get.8.en.html
    apt-get update; \
    apt-get install -y --quiet --no-install-recommends \
        libjpeg-dev \
        libmagickwand-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        zlib1g-dev \
        libicu-dev \
        libpq-dev \
        libhiredis-dev \
        libonig-dev \
        libgs-dev \
    ; \
    \
    # install and configure via docker-php-ext
    # see https://github.com/docker-library/docs/tree/master/php#how-to-install-more-php-extensions
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j "$(nproc)" \
        intl \
        xml \
        bcmath \
        ctype \
        dom \
        exif \
        fileinfo \
        gd \
        iconv \
        mbstring \
        opcache \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        zip \
    # delete output (except errors)
    > /dev/null \
    ; \
    \
    # install imagick
    # use github version for now until release from https://pecl.php.net/get/imagick is ready for PHP 8
    mkdir -p /usr/src/php/ext/imagick; \
    curl -fsSL https://github.com/Imagick/imagick/archive/06116aa24b76edaf6b1693198f79e6c295eda8a9.tar.gz | tar xvz -C "/usr/src/php/ext/imagick" --strip 1; \
    docker-php-ext-install imagick; \
    \
    # compile and install phpiredis
    git clone https://github.com/nrk/phpiredis.git ./phpiredis \
    && ( \
        cd ./phpiredis \
        && phpize \
        && ./configure --enable-phpiredis \
        && make \
        && make install \
    ) \
    && rm -rf phpiredis \
    && echo "extension=phpiredis.so" >> /usr/local/etc/php/conf.d/phpiredis.ini \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    # see https://github.com/docker-library/wordpress/blob/master/Dockerfile-debian.template
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*


#######################
# INSTALL WKHTMLTOPDF #
#######################

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN gdebi --n wkhtmltox_0.12.5-1.stretch_amd64.deb


########################
# ENABLE PHP REDIS EXT #
########################

RUN docker-php-ext-enable redis phpiredis


####################
# SETUP SUPERVISOR #
####################

RUN mkdir -p /var/log/supervisor && \
  mkdir -p /etc/supervisor/conf.d

# add supervised configs
COPY config/supervisor/supervisord.conf /etc/supervisor/


#################################
# SETUP CRON SETTINGS DIRECTORY #
#################################

RUN mkdir -p /etc/cron.d


#################
# SETUP LOGGING #
#################

# create the php application log
RUN mkdir -p /var/log/php-app
RUN chown www-data:www-data /var/log/php-app

# create the php log
RUN mkdir -p /var/log/php-fpm
RUN chown www-data:www-data /var/log/php-fpm

# create the cron log
RUN mkdir -p /var/log/cron
RUN chown www-data:www-data /var/log/cron


################################
# Define Mountable Directories #
################################

VOLUME ["/etc/supervisor/conf.d"]


###################
# DEFAULT COMMAND #
###################

EXPOSE 9000 8022

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
