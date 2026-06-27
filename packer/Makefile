.PHONY: init build-master build-worker build add-master add-worker add

PACKER ?= packer
OUTPUT_DIR := output

init:
	$(PACKER) init .

build-master: init
	$(PACKER) build master.pkr.hcl

build-worker: init
	$(PACKER) build worker.pkr.hcl

build: build-master build-worker

# Ajoute les boxes construites dans le registre Vagrant local
add-master:
	vagrant box add k8s-master $(OUTPUT_DIR)/k8s-master/virtualbox.box --force

add-worker:
	vagrant box add k8s-worker $(OUTPUT_DIR)/k8s-worker/virtualbox.box --force

add: add-master add-worker

clean:
	rm -rf $(OUTPUT_DIR)
