resource "docker_volume" "postgres_data" {
  name = "om-postgres-data"
}

resource "docker_image" "postgres" {
  name = "openmetadata/postgresql:1.12.4"
  keep_locally = true
}

resource "docker_container" "postgres" {
  name = "openmetadata-postgresql"
  image = docker_image.postgres.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  volumes {
    volume_name = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test = ["CMD-SHELL", "psql -U postgres -tAc 'select 1' -d openmetadata_db"]
    interval = "15s"
    timeout = "10s"
    retries = 10
  }

}