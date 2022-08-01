#!/bin/bash

auth_email=""      # The email used to login 'https://dash.cloudflare.com'
auth_method=""     # Set to "global" for Global API Key or "token" for Scoped API Token
auth_key=""        # Your API Token or Global API Key
zone_identifier="" # Can be found in the "Overview" tab of your domain
record_names=""    # Which records you want to be updated, seperated by spaces
discorduri=""      # Discord Hook URI

sendDiscord() {
  if [ "$discorduri" != "" ]; then
    curl -s -H "Accept: application/json" -H "Content-Type:application/json" -X POST \
      --data-raw '{
              "content" : "'"$1"'"
            }' "$discorduri"
  fi
}

###########################################
## Check if we have a public IP
###########################################
ipv4_regex='([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])'

# Read IP from args
ip=$1

# Use regex to check for proper IPv4 format.
if [[ ! $ip =~ ^$ipv4_regex$ ]]; then
  sendDiscord "DDNS Updater: Failed to find a valid IP."
  logger -s "DDNS Updater: Failed to find a valid IP."
  exit 2
fi

###########################################
## Check and set the proper auth header
###########################################
if [[ "${auth_method}" == "global" ]]; then
  auth_header="X-Auth-Key:"
else
  auth_header="Authorization: Bearer"
fi

for record_name in $record_names; do
  ###########################################
  ## Seek for the A record
  ###########################################

  logger "DDNS Updater: Check Initiated"
  record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name" \
    -H "X-Auth-Email: $auth_email" \
    -H "$auth_header $auth_key" \
    -H "Content-Type: application/json")

  ###########################################
  ## Check if the domain has an A record
  ###########################################
  if [[ $record == *"\"count\":0"* ]]; then
    logger -s "DDNS Updater: Record does not exist, perhaps create one first? (${ip} for ${record_name})"
    sendDiscord "DDNS Updater: Record '${record_name}' does not exist, perhaps create one first?"
    continue
  fi

  ###########################################
  ## Get existing IP
  ###########################################
  old_ip=$(echo "$record" | sed -E 's/.*"content":"(([0-9]{1,3}\.){3}[0-9]{1,3})".*/\1/')
  # Compare if they're the same
  if [[ $ip == $old_ip ]]; then
    logger "DDNS Updater: IP ($ip) for ${record_name} has not changed."
    continue
  fi

  ###########################################
  ## Set the record identifier from result
  ###########################################
  record_identifier=$(echo "$record" | sed -E 's/.*"id":"(\w+)".*/\1/')

  ###########################################
  ## Change the IP@Cloudflare using the API
  ###########################################
  update=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $auth_email" \
    -H "$auth_header $auth_key" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

  ###########################################
  ## Report the status
  ###########################################
  case "$update" in
  *"\"success\":false"*)
    echo -e "DDNS Updater: $ip $record_name DDNS failed for $record_identifier ($ip). DUMPING RESULTS:\n$update" | logger -s
    sendDiscord "DDNS Updater: DDNS Update Failed: '$record_name' ('$ip')."
    ;;
  *)
    logger "DDNS Updater: $ip $record_name DDNS updated."
    sendDiscord "DDNS Updater: $ip $record_name DDNS updated."
    ;;
  esac
done
