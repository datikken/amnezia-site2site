FROM php:8.3-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        libicu-dev \
        libonig-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install -j"$(nproc)" \
        intl \
        mbstring \
        opcache \
        pdo_mysql \
        zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/admin-entrypoint
COPY scaffold/ /opt/admin-scaffold/
RUN chmod +x /usr/local/bin/admin-entrypoint

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/admin-entrypoint"]
CMD ["php-fpm", "-F"]
