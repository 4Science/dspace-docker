#!/bin/bash

set +x -o pipefail

# get environment variables
source VERSION

DSPACE_VERSION=${DSPACE_VERSION:-dspace-cris-5.8.0}
DSPACE_VCS_URL=${DSPACE_VCS_URL:-https://github.com/4science/dspace}

DOCKER_TAG_tmp=$(echo $DSPACE_VERSION |cut -d- -f3-)
export DOCKER_TAG=${DOCKER_TAG:-$DOCKER_TAG_tmp}

export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-4science/dspace-cris}



function build_image(){
     docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} \
     --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
     --build-arg VCS_REF="${TRAVIS_COMMIT}" \
     --build-arg VERSION="${TRAVIS_TAG}" \
     --build-arg DSPACE_VERSION="${DSPACE_VERSION}" \
     --build-arg DSPACE_VCS_URL="${DSPACE_VCS_URL}" \
     --build-arg DSPACE_VCS_REF="${DSPACE_VCS_REF}" \
     --build-arg MODS_VERSION="${MODS_VERSION}" \
     --build-arg MODS_VCS_URL="${MODS_VCS_URL}" \
     --build-arg MODS_VCS_REF="${MODS_VCS_REF}" .
}

function get_sources(){
    echo "Clone 4science/dspace (=dspace-cris)"
    git clone --depth 1 --branch ${DSPACE_VERSION} ${DSPACE_VCS_URL} dspace

    echo "Clone modifications"
    [ -n "${MODS_VCS_URL}" ] && git clone --depth 1 "${MODS_VCS_URL}" mods || echo "No Modifications" ;
    echo "Checkout branch"
    [ -n "${MODS_VERSION}" ] && git checkout "${MODS_VERSION}" || true ;
}

function merge(){
    echo "Merge sources"
    [ -n "${MODS_VCS_URL}" ] && rsync -a mods/ dspace/ || true
}



if [[ $# -eq 0 ]]; then
  get_sources
  merge
# build image
if [ -n ${CI} ]; then
    echo "Running in CI"
else
    TRAVIS_COMMIT=$(git rev-parse HEAD)
    build_image
fi

elif [[ "${1}" == "build" ]]; then
  if [ -n ${CI} ]; then
    echo "Running in CI"
    build_image
   else
     TRAVIS_COMMIT=$(git rev-parse HEAD)
     build_image
   fi
elif [[ "${1}" == "clone" ]]; then
  get_sources
elif [[ "${1}" == "merge" ]]; then
   merge
fi
