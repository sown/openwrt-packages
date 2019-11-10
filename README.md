# SOWN-at-Home Firmware Builder

[![CircleCI](https://circleci.com/gh/sown/openwrt-packages/tree/master.svg?style=svg)](https://circleci.com/gh/sown/openwrt-packages/tree/master)

This repository contains the custom SOWN packages for SOWN-at-Home nodes, as well as a build system to compile firmware images.

As the firmware is based on [OpenWRT](https://openwrt.org/), it makes use of their [ImageBuilder system](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).

## Building the firmware

Firstly, you will need a system with the required dependencies:

- `buildroot-dev` - A SOWN server with the required dependencies. or;
- `sown-builder` Docker Image - A docker image, based on Debian Buster, with the required dependencies.

Simply run `make` inside the main directory of this repo.

## Using Docker

The docker image is defined in the `Dockerfile` in this repo.

You can build the docker image by running `docker build -t sown-builder .`

It is also built in the cloud by [Docker Hub](https://hub.docker.com). It can be accessed as `sown/builder`.

You can then make use of the image by running `docker run -it -v /path/to/repo:/path/in/container sown/builder:latest`.
