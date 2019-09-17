#!/usr/bin/env bash
#
# Create content in RStudio Connect with a given title. Does not prevent the
# creation of duplicate titles.
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

if [ $# -eq 0 ] ; then
    echo "usage: $0 <content-title>"
    exit 1
fi

# Only "name" is required by the RStudio Connect API but we use "title" for
# better presentation. We build a random name to avoid colliding with existing
# content.
TITLE="$@"

# Assign a random name. Avoid collisions so we always create something.
# Inspired by http://tldp.org/LDP/abs/html/randomvar.html
letters=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
num_letters=${#letters[*]}
NAME=$(for((i=1;i<=13;i++)); do printf '%s' "${letters[$((RANDOM%num_letters))]}"; done)

# Build the JSON to create content.
DATA=$(jq --arg title "${TITLE}" \
   --arg name  "${NAME}" \
   '. | .["title"]=$title | .["name"]=$name' \
   <<<'{}')
RESULT=$(curl --silent --show-error -L --max-redirs 0 --fail -X POST \
              -H "Authorization: Key ${CONNECT_API_KEY}" \
              --data "${DATA}" \
              "${CONNECT_SERVER}__api__/v1/experimental/content")
CONTENT=$(echo "$RESULT" | jq -r .guid)
echo "Created content: ${CONTENT}"
