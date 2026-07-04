# PRD

## Intention du projet

`infrastructure` fournit le socle Kubernetes local du POC. Il prépare un
cluster capable d'héberger `platform-cicd`, mais ne déploie pas GitLab,
ArgoCD ni les applications.

La vision globale de la chaîne CI/CD est dans
`../../control-plane/docs/prd.md`.

## Produit attendu

Le projet doit permettre de créer et provisionner un cluster local
reproductible avec :

- VMs Vagrant ;
- Kubernetes via kubeadm et containerd ;
- CNI Flannel ;
- metrics-server ;
- local-path-provisioner ;
- Gateway API ;
- MetalLB ;
- Traefik ;
- une Gateway HTTP partagée.

## Utilisateurs cibles

- Mainteneur plateforme qui veut reconstruire le socle local.
- Développeur qui veut exécuter la chaîne POC sur sa machine.
- Contributeur qui travaille sur l'IaC bas niveau.

## Critères d'acceptation

- `make up` démarre les VMs et provisionne le cluster.
- Traefik est exposé via MetalLB sur le pool configuré.
- Gateway API est disponible pour les applications.
- Une StorageClass locale par défaut existe pour les PVC du POC.
- Le dépôt plateforme peut ensuite déployer ses composants sur ce cluster.

## Non-objectifs

- Fournir un cluster de production.
- Gérer GitLab, ArgoCD ou les applications.
- Masquer les contraintes locales de virtualisation et de réseau.
