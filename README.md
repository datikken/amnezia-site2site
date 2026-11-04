# Symfony EasyAdmin

Start the Symfony EasyAdmin app and MySQL from the repository root:

```sh
go run . admin-setup
```

The first run creates the Symfony app in `admin/app`, installs EasyAdmin, and
starts PHP-FPM, nginx, and MySQL with Docker Compose. Open
<http://localhost:8080/admin> to access the panel. The sample CRUD manages
products.

To start the stack directly, run `docker compose -f admin/docker-compose.yml up -d --build`.
To stop it, run `docker compose -f admin/docker-compose.yml down`.