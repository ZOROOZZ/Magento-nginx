FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git zip unzip libzip-dev libonig-dev libxml2-dev libpng-dev libjpeg-dev \
    libfreetype6-dev libxslt-dev libicu-dev libcurl4-openssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql zip intl xsl curl soap gd bcmath opcache ftp sockets
RUN apt-get update && apt-get install -y procps netcat-openbsd


# Set working directory
WORKDIR /var/www/html

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Increase PHP memory limit
RUN echo "memory_limit = 2G" > /usr/local/etc/php/conf.d/memory-limit.ini