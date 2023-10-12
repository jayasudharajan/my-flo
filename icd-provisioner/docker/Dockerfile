FROM python:3.9.2-slim-buster

RUN echo "deb-src http://deb.debian.org/debian buster main" >> /etc/apt/sources.list
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends --yes install apt-utils
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes install build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes build-dep qt5-default
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes install libxcb-xinerama0-dev

RUN pip install --upgrade pip
RUN pip install poetry
