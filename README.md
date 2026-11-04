# Symfony EasyAdmin

Start the Symfony EasyAdmin app and MySQL from the repository root:

```sh
go run . admin-setup
```

The first run creates the Symfony app in `admin/app`, installs EasyAdmin, and
starts PHP-FPM, nginx, and PostgreSQL with Docker Compose. Open
`http://<server-ip>:8080/admin` to access the panel. The sample CRUD manages
products.

The web port is published on all host interfaces. Allow inbound TCP port 8080
in the VDS provider's firewall and the server firewall. Restrict access or put
the app behind HTTPS and authentication before using it outside development.

To start the stack directly, run `docker compose -f admin/compose.yaml up -d`.
To stop it, run `docker compose -f admin/compose.yaml down`.