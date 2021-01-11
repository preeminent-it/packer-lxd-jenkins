// Variables
variable "packages" {
  type = list(string)
  default = [
    "curl",
    "openjdk-11-jre",
    "nginx",
    "unzip"
  ]
}

variable "node_exporter_version" {
  type    = string
  default = "1.0.1"
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

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

// Image
source "lxd" "jenkins-ubuntu-focal" {
  image        = "images:ubuntu/focal"
  output_image = "jenkins-ubuntu-focal"
  publish_properties = {
    description = "Jenkins CI - Ubuntu Focal"
  }
}

// Build
build {
  sources = ["source.lxd.jenkins-ubuntu-focal"]

  // Update and install packages
  provisioner "shell" {
    inline = [
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq ${join(" ", var.packages)} < /dev/null > /dev/null"
    ]
  }

  // Install node_exporter
  provisioner "shell" {
    inline = [
      "curl -sLo - https://github.com/prometheus/node_exporter/releases/download/v${var.node_exporter_version}/node_exporter-${var.node_exporter_version}.linux-amd64.tar.gz | \n",
      "tar -zxf - --strip-component=1 -C /usr/local/bin/ node_exporter-${var.node_exporter_version}.linux-amd64/node_exporter"
    ]
  }

  // Create directories for Jenkins and Nginx
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/nginx/tls ${var.jenkins_home}"
    ]
  }

  // Create Jenkins system user
  provisioner "shell" {
    inline = [
      "useradd --system --home ${var.jenkins_home} --shell /bin/false ${var.jenkins_user}"
    ]
  }

  // Create self-signed certificate
  provisioner "shell" {
    inline = [
      "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/nginx/tls/server.key -out /etc/nginx/tls/server.crt -subj \"/CN=jenkins\""
    ]
  }

  // Install Jenkins
  provisioner "shell" {
    inline = [
      "curl -sLo /var/lib/jenkins/jenkins.war https://get.jenkins.io/war-stable/${var.jenkins_version}/jenkins.war"
    ]
  }

  // Add Jenkins Nginx config
  provisioner "file" {
    source      = "files/etc/nginx/sites-available/jenkins"
    destination = "/etc/nginx/sites-available/jenkins"
  }

  // Enable Jenkins Nginx config
  provisioner "shell" {
    inline = [
      "ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/jenkins"
    ]
  }

  // Add Jenkins default for systemd
  provisioner "file" {
    source      = "files/etc/default/jenkins"
    destination = "/etc/default/jenkins"
  }

  // Add Jenkins service
  provisioner "file" {
    source      = "files/etc/systemd/system/jenkins.service"
    destination = "/etc/systemd/system/jenkins.service"
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.jenkins_user} ${var.jenkins_home}",
      "systemctl enable jenkins"
    ]
  }
}
