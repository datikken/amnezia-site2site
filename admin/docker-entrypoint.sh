#!/bin/sh
set -eu

if [ ! -f composer.json ]; then
    composer create-project --no-interaction "symfony/skeleton:7.4.*" /tmp/symfony
    cp -a /tmp/symfony/. /var/www/html/
    rm -rf /tmp/symfony
fi

if ! grep -q '"easycorp/easyadmin-bundle"' composer.json; then
    composer require --no-interaction easycorp/easyadmin-bundle doctrine/orm-pack symfony/twig-bundle
fi

if [ ! -f .admin-scaffold-installed ]; then
    cp -a /opt/admin-scaffold/. /var/www/html/
    touch .admin-scaffold-installed
fi

php bin/console doctrine:schema:update --force --no-interaction
exec "$@"
