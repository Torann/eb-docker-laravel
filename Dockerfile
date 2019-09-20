FROM php:7.3.9-fpm

#############
# PHP SETUP #
#############

# copy config
COPY config/php/custom.ini /usr/local/etc/php/conf.d/


########################
# INSTALL DEPENDENCIES #
########################

RUN apt-get clean && apt-get update && apt-get install -y zlib1g-dev libicu-dev libpq-dev wget gdebi xmlstarlet \
    libfreetype6 xfonts-base xfonts-75dpi fonts-wqy-microhei ttf-wqy-microhei fonts-wqy-zenhei ttf-wqy-zenhei \
    libhiredis-dev libzip-dev \
    ghostscript libgs-dev \
    jpegoptim pngquant \
    libmagickwand-dev libmagickcore-dev imagemagick \
    git \
    sudo nano \
    --no-install-recommends \
    && docker-php-ext-configure intl \
    && docker-php-ext-install xml \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install ctype \
    && docker-php-ext-install dom \
    && docker-php-ext-install exif \
    && docker-php-ext-install fileinfo \
    && docker-php-ext-install gd \
    && docker-php-ext-install iconv \
    && docker-php-ext-install intl \
    && docker-php-ext-install json \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install zip \
    ## APCu
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    # GD
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    # ImageMagick
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    # Redis
    && pecl install -o -f redis \
    &&  docker-php-ext-enable redis


###############################
# BUILD AND INSTALL PHPIREDIS #
###############################

RUN git clone https://github.com/nrk/phpiredis.git ./phpiredis \
    && ( \
        cd ./phpiredis \
        && phpize \
        && ./configure --enable-phpiredis \
        && make \
        && make install \
    ) \
    && rm -rf phpiredis \
    && echo "extension=phpiredis.so" >> /usr/local/etc/php/conf.d/phpiredis.ini \
    && docker-php-ext-enable phpiredis


######################
# INSTALL SUPERVISOR #
######################

RUN apt-get install -y supervisor && \
  mkdir -p /var/log/supervisor && \
  mkdir -p /etc/supervisor/conf.d

# add supervised configs
COPY config/supervisor/supervisord.conf /etc/supervisor/


################
# INSTALL CRON #
################

RUN apt-get install -y cron
RUN mkdir -p /etc/cron.d


#######################
# INSTALL WKHTMLTOPDF #
#######################

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN gdebi --n wkhtmltox_0.12.5-1.stretch_amd64.deb


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


####################
# INSTALL COMPOSER #
####################

RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer


################################
# Define Mountable Directories #
################################

VOLUME ["/etc/supervisor/conf.d"]


###################
# DEFAULT COMMAND #
###################

EXPOSE 9000 8022

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
