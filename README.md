# Admin setup

Make sure Docker and Docker Compose are installed and running, then run this
command from the repository root:

```sh
go run . admin-setup
```

It creates the Laravel + Filament application in `admin/app` and starts it
with Docker. Open <http://localhost:8080/admin> to access the admin panel.