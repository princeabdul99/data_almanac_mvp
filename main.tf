terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "4.5.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Configure the docker provider
provider "docker" {}