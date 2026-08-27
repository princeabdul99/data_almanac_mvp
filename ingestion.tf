resource "docker_volume" "ingestion_dag_airflow" {
  name = "om-ingestion-dag-airflow"
}

resource "docker_volume" "ingestion_dags" {
  name = "om-ingestion-dags"
}

resource "docker_volume" "ingestion_tmp" {
  name = "om-ingestion-tmp"
}

resource "docker_image" "ingestion" {
  name = "openmetadata/ingestion:1.12.4"
  keep_locally = true
}

resource "docker_container" "ingestion" {
  name = "openmetadata-ingestion"
  image = docker_image.ingestion.image_id
  entrypoint = [ "/bin/bash" ]
  command = ["/opt/airflow/ingestion_dependency.sh"]

  env = [
    "AIRFLOW__API__AUTH_BACKENDS=airflow.api.auth.backend.basic_auth,airflow.api.auth.backend.session",
    "AIRFLOW__CORE__EXECUTOR=LocalExecutor",
    "AIRFLOW__OPENMETADATA_AIRFLOW_APIS__DAG_GENERATED_CONFIGS=/opt/airflow/dag_generated_configs",
    "DB_HOST=openmetadata-postgresql",
    "DB_PORT=5432",
    "AIRFLOW_DB=airflow_db",
    "DB_USER=airflow_user",
    "DB_SCHEME=postgresql+psycopg2",
    "DB_PASSWORD=airflow_pass",
   ]

   volumes {
    volume_name    = docker_volume.ingestion_dag_airflow.name
    container_path = "/opt/airflow/dag_generated_configs"
  }
  volumes {
    volume_name    = docker_volume.ingestion_dags.name
    container_path = "/opt/airflow/dags"
  }
  volumes {
    volume_name    = docker_volume.ingestion_tmp.name
    container_path = "/tmp"
  }

  ports {
    internal = 8080
    external = 8080
  }

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  restart = "unless-stopped"

  depends_on = [
    docker_container.postgres,
    docker_container.elasticsearch,
    docker_container.openmetadata_server,
  ]
}