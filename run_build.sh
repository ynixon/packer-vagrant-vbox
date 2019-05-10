#!/usr/bin/env bash
packer validate ubuntu-18.04.json
packer inspect ubuntu-18.04.json
#time packer build -var disk_size=81920 ubuntu-18.04.json
packer build -on-error=ask ubuntu-18.04.json
vagrant box add ubuntu-18.04-amd64 ubuntu-18.04-amd64-virtualbox.box --force

