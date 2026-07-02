# AGENTS.md — cluster

## Rôle du dépôt

`cluster` fournit le socle Kubernetes local du POC via Vagrant, Ansible et
Packer (provisioning bas niveau : runtime, kubeadm, réseau, add-ons). Il
héberge aussi, depuis la fusion de tout le code Ansible du POC dans ce dépôt,
le rôle `platform_bootstrap` qui installe ArgoCD/Flux/GitLab sur le cluster
pour le compte de `platform-cicd` — voir plus bas.

## Structure

```
vagrant/       Vagrantfile — 1 master + 1 worker VirtualBox
ansible/       Playbooks et rôles Ansible
  playbook.yml          Provisioning cluster (zscaler, containerd, kubeadm, add-ons)
  playbook-cluster.yml  Initialisation du cluster sur images Packer (phase 2)
  playbook-platform.yml Bootstrap ArgoCD/Flux/GitLab, appelé depuis platform-cicd
  roles/
    zscaler/           Certificat CA corporate
    containerd/        Runtime de conteneurs
    kubernetes/        Dépôts yum + packages kubeadm/kubelet/kubectl
    kubernetes-master/ Init kubeadm, flannel, metrics-server, local-path-provisioner
    kubernetes-node/   Join du worker au cluster
    kubernetes-platform/ Gateway API, MetalLB, Traefik, Gateway partagée
    platform_bootstrap/ Séquence de bootstrap ArgoCD/Flux/GitLab (une tâche/tag
                         par étape), pour le compte de platform-cicd
    argocd_trust_ca/    Rôle paramétré réutilisé deux fois par platform_bootstrap
                         (CA corporate pour argocd-repo-server, CA Gateway locale
                         pour argocd-dex-server)
packer/        Builds d'images VM reproductibles (k8s-master, k8s-worker)
```

## Rôle `platform_bootstrap` (appelé depuis `platform-cicd`)

Ce rôle exécute la logique historiquement portée par
`platform-cicd/ansible/playbook.yml` (installation ArgoCD, confiance CA,
root Application, secret SOPS pour Flux, credentials GitLab). Il ne porte
pas les scripts Python ni les manifests ArgoCD qu'il invoque (`scripts/*.py`,
`argocd/*.yaml`) — ceux-ci restent dans `platform-cicd`, propriétaire de la
séquence de bootstrap applicatif. Le rôle les référence via la variable
`platform_cicd_root` (défaut : `{{ playbook_dir }}/../../platform-cicd`,
suppose le checkout sibling standard du POC ; `platform-cicd/Makefile` la
surcharge explicitement avec `-e platform_cicd_root=$(CURDIR)`).

`platform-cicd/Makefile` invoque ce rôle en relatif
(`cd ../cluster/ansible && ansible-playbook playbook-platform.yml --tags
<étape>`) — c'est un couplage assumé entre les deux dépôts, pas une
duplication : ne pas recréer de logique de bootstrap ArgoCD/Flux/GitLab
ailleurs que dans ce rôle.

## Versions

Les versions des composants sont dans `ansible/group_vars/all.yml`. Elles
doivent rester synchronisées avec `platform.yml` du dépôt `control-plane` —
c'est `control-plane` qui fait autorité ; modifier `all.yml` seul est une
dérive.

## Commandes principales

```bash
make up                  # Démarrer les VMs et provisionner le cluster
make create-cluster      # Démarrer les VMs Packer et initialiser le cluster
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

- Ne pas dupliquer la logique de déploiement ArgoCD/GitLab/Flux ailleurs que
  dans `ansible/roles/platform_bootstrap/` — c'est le seul rôle qui porte
  cette responsabilité pour le compte de `platform-cicd`.
- Ne pas déplacer les scripts (`scripts/*.py`) ou manifests (`argocd/*.yaml`)
  de `platform-cicd` vers ce dépôt : ils restent la propriété de
  `platform-cicd`, référencés via `platform_cicd_root`.
- Ne pas modifier `group_vars/all.yml` sans mettre à jour `platform.yml` dans
  `control-plane`.
- Ne pas committer les fichiers générés dans `packer/output/` ni les fichiers
  d'état Vagrant dans `vagrant/.vagrant/`.
