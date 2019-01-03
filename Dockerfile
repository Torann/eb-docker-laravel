FROM php:7.1-fpm

##############
# COPY FILES #
##############

# php
COPY config/php/custom.ini /usr/local/etc/php/conf.d/

# supervisor
COPY config/supervisor/init.d/supervisord /etc/init.d/
COPY config/supervisor/supervisor.conf /etc/supervisor/


########################
# INSTALL DEPENDENCIES #
########################

RUN apt-get clean && apt-get update && apt-get install -y zlib1g-dev libicu-dev libpq-dev wget gdebi \
    libfreetype6 xfonts-base xfonts-75dpi fonts-wqy-microhei ttf-wqy-microhei fonts-wqy-zenhei ttf-wqy-zenhei \
    ghostscript libgs-dev \
    libmagickwand-dev libmagickcore-dev imagemagick \
    git \
    --no-install-recommends \
    && docker-php-ext-configure intl \
    && docker-php-ext-install zip \
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
    # Image Magick
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/ext-imagick.ini


######################
# INSTALL SUPERVISOR #
######################

RUN apt-get install -y supervisor

# directory for supervised containers
RUN mkdir -p /etc/supervisor/conf.d


#######################
# INSTALL WKHTMLTOPDF #
#######################

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN gdebi --n wkhtmltox_0.12.5-1.stretch_amd64.deb


#################
# SETUP LOGGING #
#################

RUN mkdir -p /var/log/php-app
RUN chown www-data:www-data /var/log/php-app


####################
# INSTALL COMPOSER #
####################

RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer


###################
# DEFAULT COMMAND #
###################

CMD ["supervisord", "-c", "/etc/supervisor/supervisor.conf"]