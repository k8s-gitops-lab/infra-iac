packer {
  required_plugins {
    vagrant = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/vagrant"
    }
    ansible = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "base_box" {
  description = "Vagrant base box (doit correspondre à vagrant/Vagrantfile)"
  default     = "bento/rockylinux-10"
}

variable "base_box_version" {
  description = "Version de la base box"
  default     = "202512.01.0"
}
