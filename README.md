# dspace-docker
[![Build Status](https://travis-ci.org/4Science/dspace-docker.svg?branch=master)](https://travis-ci.org/4Science/dspace-docker)


[Docker images for dspace &amp; dspace-cris](https://hub.docker.com/r/4science/dspace-cris/) (experimental)


### Getting Started

To get the DSpace-CRIS 5.7.0 up and running please execute:
This may take a while because the Docker image needs to be created first and therefore the source and dependencies need to be downloaded.
Afterwards `mvn package` is executed which also takes time.

```
git clone https://github.com/4science/dspace-docker
cd dspace-docker
docker-compose up -d

```
