# Symfony EasyAdmin

Start the Symfony EasyAdmin app and MySQL from the repository root:

```sh
go run . admin-setup
```

The first run creates the Symfony app in `admin/app`, installs EasyAdmin, and
starts PHP-FPM, nginx, and PostgreSQL with Docker Compose. Open
<http://localhost:8080/admin> to access the panel. The sample CRUD manages
products.

The web port is bound to the server's loopback interface. If Docker runs on a
remote server, create an SSH tunnel from your computer:

```sh
ssh -L 8080:127.0.0.1:8080 <user>@<server>
```

Keep the SSH session open, then open <http://localhost:8080/admin> in your
computer's browser.

To start the stack directly, run `docker compose -f admin/compose.yaml up -d`.
To stop it, run `docker compose -f admin/compose.yaml down`.