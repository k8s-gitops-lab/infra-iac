QEMU_BIN := /opt/homebrew/bin/qemu-system-aarch64
ENTITLEMENTS := qemu-entitlements.xml

.PHONY: up halt destroy

up:
	vagrant up --provider=virtualbox

halt:
	vagrant halt

destroy:
	vagrant destroy -f
