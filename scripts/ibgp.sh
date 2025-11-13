#!/bin/sh

# when using the `--mount` option, the host directory completely replaces the container’s /etc/frr.
# to solve this, we need a temporary container to pre-fill configuration files. 

echo "STAGE 1: Pre-populate /etc/frr files with a temporary FRR container"
sudo podman run \
  --rm -d \
  --name frr-temp \
  --privileged \
  --network host \
  quay.io/frrouting/frr:master

sudo podman cp frr-temp:/etc/frr $(pwd)/frr
sudo podman stop frr-temp

# start of the main logic
echo "STAGE 2: Launch the main FRR container"
sudo podman run \
  -d \
  --privileged \
  --name frr \
  --network host \
  --mount type=bind,source=/etc/frr,target=/etc/frr,relabel=shared \
  quay.io/frrouting/frr:master

echo "STAGE 3: Edit container's configuration files"
podman exec -it frr bash

# To be executed inside th FRR container
echo "\tEnable bgpd daemon"
sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
touch /etc/frr/bgpd.conf
chown frr:frr /etc/frr/bgpd.conf
chmod 640 /etc/frr/bgpd.conf
exit
# Finish execution inside container
podman restart frr

echo "STAGE 4: Configure FRR on servers"

