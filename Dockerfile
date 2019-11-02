FROM debian:buster

RUN apt update && apt-get install -y gawk gcc git make wget xz-utils
