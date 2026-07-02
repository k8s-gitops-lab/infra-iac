SHELL := /bin/bash -e -o pipefail
.SHELLFLAGS := -e -o pipefail -c

.PHONY: help up vagrant-up ansible-provision create-cluster ansible-cluster status down destroy

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
