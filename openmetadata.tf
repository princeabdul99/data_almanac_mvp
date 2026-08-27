
resource "docker_image" "openmetadata_server" {
  name = "openmetadata/server:1.12.4"
  keep_locally = true
}

resource "docker_container" "openmetadata_server" {
  name = "openmetadata-server"
  image = docker_image.openmetadata_server.image_id
  restart = "unless-stopped"

  env = [
    "DB_DRIVER_CLASS=org.postgresql.Driver",
    "DB_SCHEME=postgresql",
    "DB_PARAMS=allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC",
    "DB_USER=openmetadata_user",
    "DB_USER_PASSWORD=openmetadata_password",
    "DB_HOST=openmetadata-postgresql",
    "DB_PORT=5432",
    "OM_DATABASE=openmetadata_db",
    "SEARCH_TYPE=opensearch",
    "ELASTICSEARCH_HOST=openmetadata-elasticsearch",
    "ELASTICSEARCH_PORT=9200",
    "ELASTICSEARCH_SCHEME=http",
    # --ingestion service (airflow) --
    "PIPELINE_SERVICE_CLIENT_ENDPOINT=http://openmetadata-ingestion:8080",
    "AIRFLOW_USERNAME=admin",
    "AIRFLOW_PASSWORD=admin",
  ]


  ports {
    internal = 8585
    external = 8585
  }

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  healthcheck {
    test     = ["CMD-SHELL", "curl -sf http://localhost:8585/healthcheck || exit 1"]
    interval = "20s"
    timeout  = "10s"
    retries  = 15
    start_period = "60s"
  }

  depends_on = [ 
    null_resource.wait_for_migration,
    docker_container.postgres,
    docker_container.elasticsearch,
  ]
}

resource "docker_container" "openmetadata_migrate" {
  name       = "openmetadata-migrate"
  image      = docker_image.openmetadata_server.image_id
  entrypoint = ["/bin/bash"]
  command    = ["-c", "/opt/openmetadata/bootstrap/openmetadata-ops.sh migrate"]

  env = [
    "DB_DRIVER_CLASS=org.postgresql.Driver",
    "DB_SCHEME=postgresql",
    "DB_PARAMS=allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC",
    "DB_USER=openmetadata_user",
    "DB_USER_PASSWORD=openmetadata_password",
    "DB_HOST=openmetadata-postgresql",
    "DB_PORT=5432",
    "OM_DATABASE=openmetadata_db",
    "SEARCH_TYPE=opensearch",
    "ELASTICSEARCH_HOST=openmetadata-elasticsearch",
    "ELASTICSEARCH_PORT=9200",
    "ELASTICSEARCH_SCHEME=http",
  ]

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  must_run     = false
 

  depends_on = [
    docker_container.postgres,
    docker_container.elasticsearch,
  ]
}

resource "null_resource" "wait_for_migration" {
  provisioner "local-exec" {
    command = "docker wait openmetadata-migrate"
  }

  depends_on = [docker_container.openmetadata_migrate]
}