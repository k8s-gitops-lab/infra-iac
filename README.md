# cluster

Socle Kubernetes local du POC : Vagrant, Ansible, kubeadm/containerd, MetalLB, Traefik, Gateway API et Gateway partagee.

## Usage

Prerequis : les boxes Vagrant `k8s-master`/`k8s-worker` doivent deja etre
enregistrees localement (le `Vagrantfile` les reference par nom, source
`packer/output/<box>/package.box`). Sur une machine neuve, construire les
images d'abord :

```sh
make -C packer build
vagrant box add k8s-master packer/output/k8s-master/package.box --force
vagrant box add k8s-worker packer/output/k8s-worker/package.box --force
make up
```

Si les boxes sont deja enregistrees (execution precedente), `make up` seul
suffit.

Le cluster expose Traefik via MetalLB. Par defaut, le pool est configure dans `ansible/group_vars/all.yml` avec `192.168.33.100-192.168.33.120`.

Le role Ansible installe aussi `local-path-provisioner` et definit la StorageClass `local-path` comme classe par defaut pour les PVC locaux du POC.

Ce repo ne deploie pas GitLab, ArgoCD, le registry ni les applications. Ces composants vivent dans `platform-cicd`.

## Principe : build-time vs runtime

Le provisionnement est decoupes en deux phases :

### Phase 1 — construction des images Packer (`packer/`)

Toutes les taches **independantes du cluster** sont executees ici, une seule fois, pour
produire des boxes Vagrant reutilisables (`k8s-master`, `k8s-worker`). Criteres :

- pas de cluster demarre (pas d'API server, pas de token kubeadm)
- pas de dependance a la topologie reseau (IPs, noms des autres noeuds)
- aucun secret ou certificat propre a une instance specifique
- taches idempotentes valables pour toute VM issue de cette image

Exemples : installation de containerd, kubelet/kubeadm/kubectl, modules kernel,
parametres sysctl, certificats CA Zscaler, **binaire Helm**,
**desactivation permanente du swap** (`swapoff -a` + commentaire dans `/etc/fstab`).

> **Opportunite non encore exploitee**
>
> | Tache | Tag Ansible | Raison du transfert possible |
> |---|---|---|
> | Installation du binaire Helm | `helm` | Telechargement et copie d'un binaire statique : aucune dependance au cluster. Seules les commandes `helm repo add / upgrade --install` doivent rester en runtime. |

### Phase 2 — initialisation du cluster (`ansible/playbook-cluster.yml`)

Toutes les taches qui **necessitent un cluster actif** sont executees apres le demarrage
des VMs. Criteres inverses : commande qui produit ou consomme un certificat/token unique
a cette instance, ou `kubectl`/`helm` qui parle a l'API server.

| Tache | Pourquoi ce ne peut pas etre dans Packer |
|---|---|
| `kubeadm init` | Genere les certificats et tokens propres au cluster |
| kubeconfig | Depend de la sortie de `kubeadm init` |
| CNI Flannel | `kubectl apply` requiert l'API server demarre |
| metrics-server | idem |
| join-command | Token produit par `kubeadm init` sur le master |
| Join worker | Depend du master demarre et du join-command |
| Gateway API CRDs | `kubectl apply` sur cluster actif |
| local-path-provisioner | idem |
| MetalLB / Traefik | `helm upgrade --install` sur cluster actif |
| Gateway partagee | CRDs Traefik + API server requis |
