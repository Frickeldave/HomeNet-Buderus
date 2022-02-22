#!/bin/bash

# Set all static variables
_kmScriptDir=$(dirname "$(readlink -f "$0")")
_kmMagic=$(printf \\x86\\x78\\x45\\xe9\\x7c\\x4e\\x29\\xdc\\xe5\\x22\\xb9\\xa7\\xd3\\xa3\\xe0\\x7b\\x15\\x2b\\xff\\xad\\xdd\\xbe\\xd7\\xf5\\xff\\xd8\\x42\\xe9\\x89\\x5a\\xd1\\xe4)
_kmKey="init"
#_kmValue="init"
_kmPath=$1
if [ "$2" == "1" ]; then _kmLog=1; else _kmLog=0; fi

# Include configuration values
source $_kmScriptDir/buderus-km200.secret

if [ "$_kmPath" == "" ]; then printf "No path set. Leaving.\n"; exit 1; fi

function KMLog {
  local _kmMessage=$1

  if [ "$_kmLog" == "1" ]; then printf "${_kmMessage}\n" >&2; fi
}

function GetKMKey {
  _kmPart1=$(echo -n "$_kmStaticGatewayPassword$_kmMagic" | md5sum | cut -c-32)
  _kmPart2=$(echo -n "$_kmMagic$_kmUserPassword" | md5sum | cut -c-32)
  _kmKey="$_kmPart1$_kmPart2"
  _kmPart1=
  _kmPart2=
}

function GetKMData {
  local _kmGDPath=$1
  local _kmCurlOut=$(mktemp)

  KMLog "Start request to \"$_kmGDPath\""
  KMLog "Temporary file is \"$_kmCurlOut\""

  KMLog "Download from \"http://$_kmAddress/$_kmGDPath\""
  curl --fail -s -A TeleHeater http://$_kmAddress/$_kmGDPath --output $_kmCurlOut
  _kmRetCode=$?
  if [ ! $_kmRetCode == 0 ]; then echo "Failed to download data (Exitcode $_kmRetCode)."; exit 1; fi
  KMLog "Reveived value size: $(ls -lh $_kmCurlOut | awk '{print  $5}')"

  KMLog "Decrypt received value"
  _kmValue=$(grep .. $_kmCurlOut | base64 --decode | openssl enc -aes-256-ecb -d -nopad -K $_kmKey | tr '\0' '\n')
  KMLog "Received JSON is: $_kmValue"

  KMLog "Delete temporary file"
  rm -f $_kmCurlOut

  KMLog "Get value from json string"
  _kmValue=$(echo $_kmValue | jq -r '.value') 
  KMLog "Value is: $_kmValue"

  echo $_kmValue
}

GetKMKey

_kmReturn=$(GetKMData $_kmPath)

_kmPart1=
_kmPart2=
_kmKey=
echo $_kmReturn