#!/usr/bin/env bash
#
# Create a bundle, upload that bundle to RStudio Connect, deploy that bundle,
# then wait for deployment to complete.
#
# Run this script from the content root directory.
#

set -e

if [ -z "${CONNECT_SERVER}" ] ; then
    echo "The CONNECT_SERVER environment variable is not defined. It defines"
    echo "the base URL of your RStudio Connect instance."
    echo 
    echo "    export CONNECT_SERVER='http://connect.company.com/'"
    exit 1
fi

if [[ "${CONNECT_SERVER}" != */ ]] ; then
    echo "The CONNECT_SERVER environment variable must end in a trailing slash. It"
    echo "defines the base URL of your RStudio Connect instance."
    echo 
    echo "    export CONNECT_SERVER='http://connect.company.com/'"
    exit 1
fi

if [ -z "${CONNECT_API_KEY}" ] ; then
    echo "The CONNECT_API_KEY environment variable is not defined. It must contain"
    echo "an API key owned by a 'publisher' account in your RStudio Connect instance."
    echo
    echo "    export CONNECT_API_KEY='jIsDWwtuWWsRAwu0XoYpbyok2rlXfRWa'"
    exit 1
fi

if [ $# -ne 1 ] ; then
    echo "usage: $0 <content-guid>"
    exit 1
fi

CONTENT="$1"
BUNDLE_PATH="bundle.tar.gz"

# Remove any bundle from previous attempts.
rm -f "${BUNDLE_PATH}"

# Create an archive with all of our Shiny application source and data.
#
# Make sure you bundle the manifest.json and primary content files at the
# top-level; do not include the containing directory in the archive.
echo "Creating bundle archive: ${BUNDLE_PATH}"
tar czf "${BUNDLE_PATH}" manifest.json app.R data

# Upload the bundle
UPLOAD=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              --data-binary @"${BUNDLE_PATH}" \
              "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/bundles")
BUNDLE=$(echo "$UPLOAD" | jq -r .id)
echo "Created bundle: $BUNDLE"

# Deploy the bundle.
DATA=$(jq --arg bundle_id "${BUNDLE}" \
   '. | .["bundle_id"]=$bundle_id' \
   <<<'{}')
DEPLOY=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              --data "${DATA}" \
              "${CONNECT_SERVER}__api__/v1/content/${CONTENT}/deploy")
TASK=$(echo "$DEPLOY" | jq -r .task_id)

# Poll until the task completes.
FINISHED=false
CODE=-1
FIRST=0
echo "Deployment task: ${TASK}"
while [ "${FINISHED}" != "true" ] ; do
    DATA=$(curl --silent --show-error -L --max-redirs 0 --fail \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              "${CONNECT_SERVER}__api__/v1/tasks/${TASK}?wait=1&first=${FIRST}")
    # Extract parts of the task status.
    FINISHED=$(echo "${DATA}" | jq .finished)
    CODE=$(echo "${DATA}" | jq .code)
    FIRST=$(echo "${DATA}" | jq .last)
    # Present the latest output lines.
    echo "${DATA}" | jq  -r '.output | .[]'
done

if [ "${CODE}" -ne 0 ]; then
    ERROR=$(echo "${DATA}" | jq -r .error)
    echo "Task: ${TASK} ${ERROR}"
    exit 1
fi
echo "Task: ${TASK} Complete."
