TARGETS := $(shell ls scripts | grep -vE 'clean|run|help|release*|build-moby|run-moby')

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-`uname -s`-`uname -m|sed 's/v7l//'` > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(TARGETS): .dapper
	./.dapper $@

trash: .dapper
	./.dapper -m bind trash

trash-keep: .dapper
	./.dapper -m bind trash -k

deps: trash

build/initrd/.id: .dapper
	./.dapper prepare

run: build/initrd/.id .dapper
	./.dapper -m bind build-target
	./scripts/run

build-moby:
	./scripts/build-moby

run-moby:
	./scripts/run-moby

shell-bind: .dapper
	./.dapper -m bind -s

clean:
	@./scripts/clean

release: .dapper release-build

release-build:
	mkdir -p dist
	./.dapper release 2>&1 | tee dist/release.log

rpi64:
	# scripts/images/raspberry-pi-hypriot64/dist/rancheros-raspberry-pi.zip
	cp dist/artifacts/rootfs_arm64.tar.gz scripts/images/raspberry-pi-hypriot64/
	cd scripts/images/raspberry-pi-hypriot64/ \
		&& ../../../.dapper

vmware: .dapper
	mkdir -p dist
	APPEND_SYSTEM_IMAGES="rancher/os-openvmtools:10.2.5-3" \
	VMWARE_APPEND="console=tty1 console=ttyS0,115200n8 printk.devkmsg=on rancher.autologin=tty1 rancher.autologin=ttyS0 rancher.autologin=ttyS1 panic=10" \
	./.dapper release-vmware 2>&1 | tee dist/release.log

hyperv: .dapper
	mkdir -p dist
	APPEND_SYSTEM_IMAGES="rancher/os-hypervvmtools:v4.14.85-rancher-1" \
	./.dapper release-hyperv 2>&1 | tee dist/release.log

help:
	@./scripts/help

.DEFAULT_GOAL := default

.PHONY: $(TARGETS)
