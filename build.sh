#!/bin/sh
docker build --progress=plain \
  -t technicalguru/mailserver-postfix:latest \
  --build-arg PF_PACKAGE="3.7.9-0+deb12u1" \
  .
