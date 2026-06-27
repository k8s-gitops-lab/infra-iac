variable "master_output_name" {
  default = "k8s-master"
}

source "vagrant" "master" {
  source_path          = var.base_box
  box_version          = var.base_box_version
  provider             = "virtualbox"
  output_dir           = "output/${var.master_output_name}"
  communicator         = "ssh"
  add_force            = false
  skip_add             = true
}

build {
  name    = "k8s-master"
  sources = ["source.vagrant.master"]

  provisioner "ansible" {
    playbook_file = "../ansible/playbook.yml"

    # Place l'hôte Packer dans les groupes du playbook existant
    groups = ["kubernetes", "kubernetes-master"]

    # Exclut les étapes cluster-dépendantes (init kubeadm, CNI, kubeconfig, métriques)
    # et le rôle kubernetes-platform (MetalLB, Traefik) — cluster non démarré à ce stade
    extra_arguments = [
      "--skip-tags", "kubeadm,kubeconfig,cni,flannel,metrics-server,join-command,platform",
      "-e", "kubeconfig_local_update=false",
    ]

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }
}
