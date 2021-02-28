variable "source" {
  type = map(string)
  default = {
    description = "Hashicorp Consul - Ubuntu 20.04"
    image       = "base-ubuntu-focal"
    name        = "consul-ubuntu-focal"
  }
}

variable "jenkins_home" {
  type    = string
  default = "/var/lib/jenkins"
}

variable "jenkins_version" {
  type    = string
  default = "2.263.1"
}

variable "jenkins_user" {
  type    = string
  default = "jenkins"
}

