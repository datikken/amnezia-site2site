# Laravel Filament admin

From the repository root, run:

```sh
go run . admin-setup
```

The command creates a Laravel 12 application with Filament 3 in `admin/app`,
then starts PHP-FPM and nginx with Docker Compose. Open
<http://localhost:8080/admin> to access the panel.

When setup runs in a terminal, it offers to create the first Filament user.
To create one later, run:

```sh
docker compose -f admin/docker-compose.yml exec app php artisan make:filament-user
```
