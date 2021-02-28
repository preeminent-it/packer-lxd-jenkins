// Image
source "lxd" "main" {
  image        = "${var.source.image}"
  output_image = "${var.source.name}"
  publish_properties = {
    description = "${var.source.description}"
  }
}

// Build
build {
  sources = ["source.lxd.main"]

  // Create directories for Jenkins
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

  // Install 
  provisioner "shell" {
    inline = [
      "curl -so - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -",
      "echo 'deb https://pkg.jenkins.io/debian-stable binary/' > /etc/apt/sources.list.d/jenkins.list",
      "apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq openjdk-11-jre < /dev/null > /dev/null",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq jenkins nginx < /dev/null > /dev/null"
    ]
  }

  // Add Jenkins Nginx config
  provisioner "file" {
    source      = "files/etc/nginx/sites-available"
    destination = "/etc/nginx/"
  }

  // Enable Jenkins Nginx config
  provisioner "shell" {
    inline = [
      "ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/jenkins"
    ]
  }

  // Set file ownership and enable the service
  provisioner "shell" {
    inline = [
      "chown -R ${var.jenkins_user} ${var.jenkins_home}",
      "systemctl enable jenkins"
    ]
  }
}
