#!/bin/bash -x
#
#
# Reference: https://docs.docker.com/registry/deploying/
REGISTRY_IP=$1
REGISTRY_PORT=${2:-5000}

if [ -z "$REGISTRY_IP" ]; then
  REGISTRY_IP=$(juju run -u docker-registry/leader "unit-get public-address" || echo localhost)
fi

if [ "$REGISTRY_IP" == "localhost" ];then
  nc -z $REGISTRY_IP $REGISTRY_PORT || docker run -d -p $REGISTRY_PORT:$REGISTRY_PORT --restart=always --name registry registry:2
fi

while IFS='$\n' read -r IMAGE; do
  # skip comments
  [[ "$IMAGE" =~ ^#.*$ ]] && continue

  IMAGE_NAME="$(echo $IMAGE | rev | cut -d'/' -f1 | rev)"

  # does the image already exist?
  docker image pull -q --tls-verify=false $REGISTRY_IP:$REGISTRY_PORT/${IMAGE_NAME}
  if [ "x$?" != "x0" ];then
    # download the image from the upstream registry
    docker pull $IMAGE
    # tag the image to allow it to be pushed to the local registry.
    docker tag ${IMAGE_NAME} $REGISTRY_IP:$REGISTRY_PORT/${IMAGE_NAME}
    # upload the image to the local registry
    docker push --tls-verify=false $REGISTRY_IP:$REGISTRY_PORT/${IMAGE_NAME}
    # remove locally cached images.
    docker image rm ${IMAGE_NAME}
    docker image rm $REGISTRY_IP:$REGISTRY_PORT/${IMAGE_NAME}
    # verify the image can be downloaded.
    docker image pull --tls-verify=false $REGISTRY_IP:$REGISTRY_PORT/${IMAGE_NAME}
  fi
done
