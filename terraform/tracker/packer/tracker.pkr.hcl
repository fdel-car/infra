packer {
  required_plugins {
    amazon = {
      version = "1.0.4"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "hcp-packer-iteration" "golden" {
  bucket_name = "golden"
}

data "hcp-packer-image" "golden" {
  bucket_name    = "golden"
  iteration_id   = data.hcp-packer-iteration.golden.id
  cloud_provider = "aws"
  region         = "eu-west-3"
}

source "amazon-ebs" "tracker" {
  ami_name      = "tracker-{{timestamp}}"
  instance_type = "t2.micro"
  region        = "eu-west-3"
  source_ami    = data.hcp-packer-image.golden.id
  ssh_username  = "ubuntu"
}

build {
  hcp_packer_registry {
    description = "Tracker application."
  }
  name = "tracker"
  sources = [
    "source.amazon-ebs.tracker",
  ]

  provisioner "shell" {
    # Temporary inline commands to test the image
    inline_shebang = "/bin/bash -ie"
    inline = [
      "npx create-react-app tracker",
      "cd tracker",
      "yarn build",
      "pm2 serve build",
      "pm2 save"
    ]
  }
}
