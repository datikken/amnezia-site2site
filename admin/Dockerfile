FROM php:8.3-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        composer \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libsqlite3-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        opcache \
        pdo_sqlite \
        zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY bootstrap.sh /usr/local/bin/admin-bootstrap
RUN chmod +x /usr/local/bin/admin-bootstrap

CMD ["php-fpm"]
