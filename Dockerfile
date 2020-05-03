FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y \
	iproute2 \
	iputils-ping \
	traceroute \
	tcpdump \
	dnsmasq \
	netcat-openbsd \
	python3 \
	curl \
	wget \
	gawk \
	dnsutils \
	procps
