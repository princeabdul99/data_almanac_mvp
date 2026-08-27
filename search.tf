resource "docker_volume" "elasticsearch_data" {
 name = "om-elasticsearch-data"
}

resource "docker_image" "elasticsearch" {
  name         = "opensearchproject/opensearch:2.11.1"
  keep_locally = true
}

resource "docker_container" "elasticsearch" {
  name = "openmetadata-elasticsearch"
  image = docker_image.elasticsearch.image_id
  restart = "unless-stopped"

  env = [
    "discovery.type=single-node",
    "plugins.security.disabled=true",
    "OPENSEARCH_JAVA_OPTS=-Xms1024m -Xmx1024m",
    ]

  volumes {
    volume_name = docker_volume.elasticsearch_data.name
    container_path = "/usr/share/opensearch/data"
  }

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  healthcheck {
    test     = ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -qE '\"status\":\"(green|yellow)\"'"]
    interval = "15s"
    timeout  = "10s"
    retries  = 10
  }
}

# --- Pull Kibana (must match Elasticsearch's version exactly)
resource "docker_image" "kibana" {
  name         = "opensearchproject/opensearch-dashboards:2.11.1"
  keep_locally = true
}

resource "docker_container" "kibana" {
  name = "openmetadata-kibana"
  image = docker_image.kibana.image_id
  restart = "unless-stopped"

  env = [
    "OPENSEARCH_HOSTS=[\"http://openmetadata-elasticsearch:9200\"]",
    "DISABLE_SECURITY_DASHBOARDS_PLUGIN=true",
  ]

  ports {
    internal = 5601
    external = 5601
  }

  networks_advanced {
    name = docker_network.openmetadata_net.name
  }

  depends_on = [docker_container.elasticsearch]
}