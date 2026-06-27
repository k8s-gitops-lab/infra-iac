variable "worker_output_name" {
  default = "k8s-worker"
}

source "vagrant" "worker" {
  source_path          = var.base_box
  box_version          = var.base_box_version
  provider             = "virtualbox"
  output_dir           = "output/${var.worker_output_name}"
  communicator         = "ssh"
  add_force            = false
  skip_add             = true
}

build {
  name    = "k8s-worker"
  sources = ["source.vagrant.worker"]

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"

    # Place l'hôte Packer dans les groupes du playbook existant
    groups = ["kubernetes", "kubernetes-node"]

    # Exclut uniquement le join au cluster — le master n'existe pas encore à ce stade
    extra_arguments = [
      "--skip-tags", "join",
    ]

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }
}
