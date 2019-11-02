FROM debian:buster

RUN apt update && apt-get install -y build-essential bzip2 gawk git zlib1g-dev libncurses5-dev flex python2 unzip wget xz-utils
