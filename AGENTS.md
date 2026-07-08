# AGENTS.md — infrastructure

## Rôle du dépôt

`infrastructure` fournit le socle Kubernetes local du POC via Vagrant, Ansible et
Packer (provisioning bas niveau : runtime, kubeadm, réseau, add-ons). Il ne
déploie pas ArgoCD, GitLab ni les applications — ce bootstrap applicatif vit
dans `platform-cicd` (rôle Ansible `platform_bootstrap`, cf.
`platform-cicd/AGENTS.md`).

## Structure

```
vagrant/       Vagrantfile — 1 master + 1 worker VirtualBox
ansible/       Playbooks et rôles Ansible
  playbook.yml          Provisioning cluster (zscaler, containerd, kubeadm, add-ons)
  playbook-cluster.yml  Initialisation du cluster sur images Packer (phase 2)
  roles/
    zscaler/           Certificat CA corporate
    containerd/        Runtime de conteneurs
    kubernetes/        Dépôts yum + packages kubeadm/kubelet/kubectl
    kubernetes-master/ Init kubeadm, flannel, metrics-server, local-path-provisioner
    kubernetes-node/   Join du worker au cluster
    kubernetes-platform/ Gateway API, MetalLB, Traefik, Gateway partagée
packer/        Builds d'images VM reproductibles (k8s-master, k8s-worker)
```

## Versions

Les versions des composants sont dans `ansible/group_vars/all.yml`. Elles
doivent rester synchronisées avec `platform.yml` du dépôt `control-plane` —
c'est `control-plane` qui fait autorité ; modifier `all.yml` seul est une
dérive.

## Commandes principales

```bash
make up                  # Démarrer les VMs et provisionner le cluster
make create-cluster      # Démarrer les VMs Packer et initialiser le cluster
make snapshot-cluster    # Snapshot VirtualBox de master-01/worker-01 (SNAPSHOT_NAME, defaut cluster-ready)
make restore-cluster     # Restaure master-01/worker-01 depuis un snapshot VirtualBox
make down                # Éteindre les VMs sans les détruire
make destroy             # Détruire les VMs
cd packer && make build  # Construire les images VM Packer
```

## Provisioning des images Packer

Les images Packer (`packer/master.pkr.hcl`, `packer/worker.pkr.hcl`) doivent
être provisionnées via le `provisioner "ansible"` (réutilisant
`ansible/playbook.yml` avec `--skip-tags` pour exclure les étapes
cluster-dépendantes), pas via un `provisioner "shell"` ad hoc. C'est déjà le
cas aujourd'hui — ne pas régresser vers du shell inline en cas de nouvelle
étape de provisioning : ajouter un rôle/tag Ansible et l'inclure dans le
playbook existant.

## Contraintes Vagrant / QEMU

- Ne pas proposer de workflow nécessitant Vagrant ou QEMU en root.
- Pour le provider QEMU, ne pas utiliser le pattern réseau point-à-point où le
  master écoute et le worker se connecte.

## Ce qu'il ne faut pas faire

- Ne pas ajouter de logique de déploiement ArgoCD/GitLab/Flux dans ce dépôt :
  elle vit dans le rôle Ansible `platform_bootstrap` de `platform-cicd`.
- Ne pas modifier `group_vars/all.yml` sans mettre à jour `platform.yml` dans
  `control-plane`.
- Ne pas committer les fichiers générés dans `packer/output/` ni les fichiers
  d'état Vagrant dans `vagrant/.vagrant/`.
