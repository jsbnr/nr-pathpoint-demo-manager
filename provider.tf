terraform {
  required_version = "~> 1.13.5"
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.76.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "newrelic" {
  region = "US"
}