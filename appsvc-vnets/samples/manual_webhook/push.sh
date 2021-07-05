if [[ "$#" -ne 6 ]]; then
    echo -e "Incorrect number of arguments.  You need to provide:\nImage Repository\nImage Tag\nRegistry FQDN\nWebhook URL\nWebhook User\nWebhook Password"
    exit 1
fi

IMAGE_REPOSITORY=$1
IMAGE_TAG=$2
REGISTRY_FQDN=$3
HOOK_URL=$4
HOOK_USER=$5
HOOK_PASSWORD=$6

HOOK_ID=$(uuidgen)
HOOK_TIMESTAMP=$(date -u -Iseconds)
REQUEST_ID=$(uuidgen)

#Until the docker manifest command is out of testing we have to query the image and hope the 1st digest
#matches the manifest we just sent to our repo
str=$(docker image inspect --format='{{index .RepoDigests 01}}' $REGISTRY_FQDN/$IMAGE_REPOSITORY)
if [[ -z "$str" ]]; then
    echo "Unable to find manifest digest"
    exit 1
fi
IFS='@'
read -ra ADDR <<< "$str"
MANIFEST_DIGEST=${ADDR[1]}
if [[ -z "$MANIFEST_DIGEST" ]]; then
    echo "Unable to parse manifest digest"
    exit 1
fi

#Until the docker manifest command is out of testing we have to run the push again and parse 
#the manifest size out of the command output.  
MANIFEST_SIZE=$(echo $(docker push $REGISTRY_FQDN/$IMAGE_REPOSITORY ) | egrep -o "size\: [0-9]+" | sed 's/size\: //')
if [[ -z "$MANIFEST_SIZE" ]]; then
    echo "Unable to parse manifest size"
    exit 1
fi

read -d '' BODY << EOF
{
  "id": "$HOOK_ID",
  "timestamp": "$HOOK_TIMESTAMP",
  "action": "push",
  "target": {
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "size": $MANIFEST_SIZE,
    "digest": "$MANIFEST_DIGEST",
    "length": $MANIFEST_SIZE,
    "repository": "$IMAGE_REPOSITORY",
    "tag": "$IMAGE_TAG"
  },
  "request": {
    "id": "$REQUEST_ID",
    "host": "$REGISTRY_FQDN",
    "method": "PUT",
    "useragent": "docker/19.03.13 go/go1.15.1 git-commit/4484c46 kernel/5.11.11-200.fc33.x86_64 os/linux arch/amd64 UpstreamClient(Docker-Client/19.03.13 \\(linux\\))"
  }
}
EOF

echo "JSON IS"
echo $BODY

curl -X POST \
    -u "$HOOK_USER:$HOOK_PASSWORD" \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "Content-Length: ${#BODY}" \
    --data "$BODY" \
    $HOOK_URL

