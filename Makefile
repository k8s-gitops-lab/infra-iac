SHELL := /bin/bash -e -o pipefail
.SHELLFLAGS := -e -o pipefail -c

SNAPSHOT_NAME ?= cluster-ready

.PHONY: help up vagrant-up ansible-provision create-cluster ansible-cluster status down destroy snapshot-cluster restore-cluster

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

up: vagrant-up ansible-provision ## Demarre/provisionne le cluster complet (boxes k8s-master/k8s-worker deja enregistrees requises, cf. README)

vagrant-up: ## Demarre les VMs du cluster Kubernetes
	cd vagrant && vagrant up --provider=virtualbox

ansible-provision: ## Provisionne Kubernetes, MetalLB, Traefik et la Gateway partagee
	cd ansible && ansible-galaxy collection install -r requirements.yml
	cd ansible && ansible-playbook -i inventory.ini playbook.yml

create-cluster: vagrant-up ansible-cluster ## Demarre les VMs Packer et initialise le cluster (phase 2)

ansible-cluster: ## Initialise le cluster sur les images Packer (kubeadm, join, platform)
	cd ansible && ansible-galaxy collection install -r requirements.yml
	cd ansible && ansible-playbook -i inventory.ini playbook-cluster.yml

status: ## Affiche l'etat Vagrant
	cd vagrant && vagrant status

down: ## Eteint les VMs sans les detruire
	cd vagrant && vagrant halt

destroy: ## Detruit les VMs Vagrant
	cd vagrant && vagrant destroy -f

snapshot-cluster: ## Snapshot VirtualBox de master-01/worker-01 (SNAPSHOT_NAME, defaut cluster-ready)
	cd vagrant && vagrant snapshot save --force master-01 "$(SNAPSHOT_NAME)" && vagrant snapshot save --force worker-01 "$(SNAPSHOT_NAME)"

restore-cluster: ## Restaure master-01/worker-01 depuis un snapshot VirtualBox (SNAPSHOT_NAME, defaut cluster-ready)
	cd vagrant && vagrant snapshot restore master-01 "$(SNAPSHOT_NAME)" && vagrant snapshot restore worker-01 "$(SNAPSHOT_NAME)"
