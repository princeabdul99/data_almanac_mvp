variable "postgres_password" {
    description = "Superuser password for the OpenMetadata Postgres container"
    type = string
    sensitive = true
}