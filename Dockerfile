FROM php:7.1-fpm

COPY config/custom.ini /usr/local/etc/php/conf.d/

RUN apt-get clean && apt-get update && apt-get install -y zlib1g-dev libicu-dev libpq-dev libfreetype6 wget gdebi xfonts-base xfonts-75dpi fonts-wqy-microhei ttf-wqy-microhei fonts-wqy-zenhei ttf-wqy-zenhei libpng12-0 urw-fonts libXext openssl-devel libXrender xorg-x11-fonts-cyrillic.noarch cjkuni-fonts-ghostscript.noarch cjkuni-ukai-fonts.noarch cjkuni-uming-fonts.noarch vlgothic-fonts.noarch texlive-uhc.noarch libmagickwand-dev libmagickcore-dev imagemagick \
    --no-install-recommends \
    && docker-php-ext-install opcache \
    && docker-php-ext-install intl \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install pdo_pgsql \
    && docker-php-ext-install zip \
    ## APCu
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    # Image Magick
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/ext-imagick.ini

# Install wkhtmltopdf
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.2.1/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb
RUN gdebi --n wkhtmltox-0.12.2.1_linux-jessie-amd64.deb

RUN mkdir -p /var/log/php-app
RUN chown www-data:www-data /var/log/php-app

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer