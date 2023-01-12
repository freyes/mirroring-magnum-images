#!/bin/bash -eux
#
#
# Reference: https://docs.docker.com/registry/deploying/
REGISTRY_IP=localhost

nc -z $REGISTRY_IP 5000 || docker run -d -p 5000:5000 --restart=always --name registry registry:2

while IFS='$\n' read -r IMAGE; do
  # skip comments
  [[ "$IMAGE" =~ ^#.*$ ]] && continue

  IMAGE_NAME="$(echo $IMAGE | rev | cut -d'/' -f1 | rev)"

  # download the image from the upstream registry
  docker pull $IMAGE
  # tag the image to allow it to be pushed to the local registry.
  docker tag ${IMAGE_NAME} $REGISTRY_IP:5000/${IMAGE_NAME}
  # upload the image to the local registry
  docker push --tls-verify=false $REGISTRY_IP:5000/${IMAGE_NAME}
  # remove locally cached images.
  docker image rm ${IMAGE_NAME}
  docker image rm $REGISTRY_IP:5000/${IMAGE_NAME}
  # verify the image can be downloaded.
  docker image pull --tls-verify=false $REGISTRY_IP:5000/${IMAGE_NAME}
done
