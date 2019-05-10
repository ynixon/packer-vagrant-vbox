#!/usr/bin/env bash
mkdir -p test && cd test
vagrant init ubuntu-18.04-amd64
time vagrant up
