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
    libxpm4 libxrender1 libgtk2.0-0 libnss3 libgconf-2-4 chromium-browser xvfb gtk2-engines-pixbuf \
    xfonts-cyrillic xfonts-100dpi xfonts-scalable imagemagick x11-apps \
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
    && docker-php-ext-enable imagick


#######################
# INSTALL WKHTMLTOPDF #
#######################

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb
RUN gdebi --n wkhtmltox_0.12.5-1.stretch_amd64.deb


####################
# INSTALL COMPOSER #
####################

RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer


###################
# DEFAULT COMMAND #
###################

EXPOSE 9000 8022