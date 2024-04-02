#!/bin/bash

function cleanup() {
    echo "Removing runner..."
    $runner_home/config.sh remove --token ${registration_token}
}

function exitWithError() {
  message=$*
  consoleLog $message
  exit 1
}

function consoleLog() {
  message=$*
  echo "$(date) - $message"
}

function validate() {
 
  if [ -z ${owner+x} ]; then
    exitWithError "Missing environment variable 'owner'. Ex; AIM, innsh. Exiting";   
  else   
    consoleLog "Environment variable 'owner' set to '$owner'";   
  fi

  if [ -z ${repo+x} ]; then
    exitWithError "Missing environment variable 'repo'. Exiting";   
  else   
    consoleLog "Environment variable 'repo' set to '$repo'";   
  fi

  if [ -z ${token+x} ]; then
    exitWithError "Missing environment variable 'token'. Exiting";   
  else   
    consoleLog "Environment variable 'token' is set";   
  fi

}

function welcome()  {

  echo 
  echo "runner_home:$runner_home"
  echo 
}

# Main

owner=$owner
repo=$repo
token=$token
app=ghar
welcome

validate

runnerId="ghar-${repo}-$(hostname)"
response=$(curl -w "http_status_code:%{http_code}" -sX POST https://github.softwareag.com/api/v3/repos/${owner}/$repo/actions/runners/registration-token -H Accept:'application/vnd.github+json' -H Authorization:"Bearer $token")
http_status_code=$(echo $response | grep -o "http_status_code:[0-9]\+" | cut -d":" -f2)
json_response=$(echo $response | sed -e "s/http_status_code:[0-9]\+//")
[[ $http_status_code -ge 200 && $http_status_code -le 299 ]] || exitWithError "Error while creating registration token. Here is the response from server: $(echo $json_response | jq -c)"

registration_token=$(echo $json_response | jq .token --raw-output)
consoleLog "Registration token for self hosted runner fetched. Token length $(echo $registration_token | wc)"
$runner_home/config.sh --unattended --url https://github.softwareag.com/${owner}/${repo} --token ${registration_token} --name "$runnerId" --labels $repo

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
consoleLog "Runner identifier: $runnerId"
$runner_home/run.sh & wait $!
