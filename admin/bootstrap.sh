#!/bin/sh
set -eu

if [ ! -f artisan ]; then
    composer create-project --prefer-dist --no-interaction "laravel/laravel:^12.0" .
else
    composer install --no-interaction
fi

if ! grep -q '"filament/filament"' composer.json; then
    composer require --no-interaction -W "filament/filament:^3.3"
fi

if [ ! -f app/Providers/Filament/AdminPanelProvider.php ]; then
    printf 'admin\n' | php artisan filament:install --panels
fi

mkdir -p database
touch database/database.sqlite

if ! grep -q '^APP_KEY=base64:' .env; then
    php artisan key:generate --force
fi

php artisan migrate --force
chown -R www-data:www-data database storage bootstrap/cache

if [ -t 0 ]; then
    printf 'Create a Filament admin user now? [Y/n] '
    read -r answer
    case "$answer" in
        n|N|no|NO)
            ;;
        *)
            php artisan make:filament-user
            ;;
    esac
else
    printf 'Create an admin user with: docker compose -f admin/docker-compose.yml exec app php artisan make:filament-user\n'
fi
