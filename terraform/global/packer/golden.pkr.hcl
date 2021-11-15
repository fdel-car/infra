packer {
  required_plugins {
    amazon = {
      version = "1.0.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "golden-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "eu-west-3"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
}

build {
  hcp_packer_registry {
    description = "Ubuntu golden image configured with node, yarn and pm2."
  }
  name = "golden"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    scripts = [
      "./setup.sh"
    ]
  }
}
