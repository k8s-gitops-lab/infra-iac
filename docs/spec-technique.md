# Spec technique

## Entrées principales

- `Makefile` expose `up`, `vagrant-up`, `ansible-provision`, `create-cluster`,
  `ansible-cluster`, `status`, `down` et `destroy`.
- `vagrant/Vagrantfile` décrit les VMs.
- `ansible/playbook.yml` provisionne le socle courant.
- `ansible/playbook-cluster.yml` initialise un cluster depuis les images
  Packer.
- `ansible/group_vars/all.yml` centralise les versions et plages réseau.
- `packer/` contient les définitions d'images master et worker.

## Versions et réseau

La configuration actuelle cible Kubernetes `1.36.2`, Flannel `v0.28.5`,
metrics-server `v0.8.1`, Gateway API `v1.5.1` et MetalLB chart `0.14.9`.

Le pool MetalLB par défaut est `192.168.33.100-192.168.33.120`. Les subnets
Kubernetes sont `10.244.0.0/16` pour les pods et `10.96.0.0/12` pour les
services.

## Provisionnement

`vagrant/Vagrantfile` référence les boxes par nom (`k8s-master`, `k8s-worker`)
avec pour source `packer/output/<box>/package.box` : `vagrant up` (donc
`make up` et `make create-cluster`, qui l'appellent tous les deux via
`vagrant-up`) suppose que ces boxes ont déjà été construites (`make -C
packer build`) et enregistrées localement (`vagrant box add`). Il n'y a plus
de chemin indépendant de Packer.

`make up` exécute :

1. `vagrant up --provider=virtualbox` dans `vagrant/` ;
2. `ansible-galaxy collection install -r requirements.yml` ;
3. `ansible-playbook -i inventory.ini playbook.yml`.

`make create-cluster` démarre les VMs puis lance `playbook-cluster.yml`
(phase 2 : initialisation du cluster sur les images Packer déjà construites).

## Frontière de responsabilité

Ce dépôt prépare le cluster et les add-ons réseau bas niveau. Les composants
applicatifs et GitOps sont déclarés dans `platform-cicd`.
