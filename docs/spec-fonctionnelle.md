# Spec fonctionnelle

## Parcours principal

L'utilisateur lance `make up`. Cette cible démarre les VMs avec Vagrant puis
exécute le provisionnement Ansible.

Le résultat attendu est un cluster Kubernetes prêt à recevoir la plateforme
applicative.

## Phases

Le projet distingue deux phases :

- build-time, avec Packer, pour préparer des images VM réutilisables ;
- runtime, avec Vagrant et Ansible, pour initialiser le cluster actif.

Les tâches qui nécessitent l'API server, des tokens ou des certificats propres
à l'instance restent en runtime.

## Services de socle

Le cluster fournit :

- le réseau pod via Flannel ;
- l'exposition HTTP via Traefik ;
- les adresses LoadBalancer via MetalLB ;
- les CRDs Gateway API ;
- une Gateway partagée ;
- le stockage local via local-path-provisioner ;
- les métriques via metrics-server.

## Relation avec les autres projets

`poc-devops-platform` dépend de ce socle. Les applications et leurs manifests
ne sont pas installés ici.
