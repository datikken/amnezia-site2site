# Symfony EasyAdmin

From the repository root, run:

```sh
go run . admin-setup
```

Or start the stack directly:

```sh
docker compose -f admin/docker-compose.yml up -d --build
```

The first start creates a Symfony 7.4 app in `app/`, installs EasyAdmin and
Doctrine, creates the sample Product table, and starts PHP-FPM, nginx, and
MySQL. Visit <http://localhost:8080/admin> to manage products.

Stop the containers with:

```sh
docker compose -f admin/docker-compose.yml down
```

MySQL data is kept in the `mysql_data` Docker volume. The included database
credentials are for local development; change them before using this setup
outside a trusted development environment.
