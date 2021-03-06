#!/usr/bin/env sh

# DNS API for acme.sh for users using GleSYS (https://glesys.se).
# Created by Jakob Ruhe 2018-03-16.
# Report Bugs here: https://github.com/jakeru/dns_glesys.acme.sh

########  Public functions #####################

# Adds a TXT DNS record.
# Usage:
# dns_glesys_add _acme-challenge.example.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_glesys_add() {
  fulldomain=$1
  txtvalue=$2

  _info "Using Glesys"
  _info fulldomain "$fulldomain"
  _info txtvalue "$txtvalue"

  Glesys_User="${Glesys_User:-$(_readaccountconf_mutable Glesys_User)}"
  Glesys_Token="${Glesys_Token:-$(_readaccountconf_mutable Glesys_Token)}"
  if [ -z "$Glesys_User" ]; then
    _err "You must export variable: Glesys_User"
    return 1
  fi
  if [ -z "$Glesys_Token" ]; then
    _err "You must export variable: Glesys_Token"
    return 1
  fi

  # Now save the credentials.
  _saveaccountconf_mutable Glesys_Token "$Glesys_Token"
  _saveaccountconf_mutable Glesys_User "$Glesys_User"

  if ! _glesys_get_domain; then
    return 1
  fi

  _body="{\"domainname\":\"$_glesys_domain\",\"host\":\"$_glesys_host\",\"type\":\"TXT\",\"ttl\":300,\"data\":\"$txtvalue\"}"
  _glesys_rest "$_body" "domain/addrecord"

  _dns_glesys_recordid=$(echo "$_response" | jq .response.record.recordid)
  _debug "recordid of added record: $_dns_glesys_recordid"

  return 0
}

# Removes the txt record after validation.
# Usage:
#  dns_glesys_rm _acme-challenge.example.com  "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_glesys_rm() {
  fulldomain=$1
  txtvalue=$2

  _info "Deleting record $fulldomain"

  if ! _glesys_get_domain; then
    return 1
  fi

  _body="{\"domainname\":\"$_glesys_domain\"}"
  _glesys_rest "$_body" "domain/listrecords"
  _dns_glesys_rm_recordid=$(echo "$_response" | jq ".response.records[]|select(.host==\"$_glesys_host\")|.recordid")

  _debug "Record id to delete: $_dns_glesys_rm_recordid"

  _body="{\"recordid\":\"$_dns_glesys_rm_recordid\"}"
  _glesys_rest "$_body" "domain/deleterecord"

  return 0
}

####################  Private functions below ##################################

# Usage:
#  fulldomain="sub.example.com"
#  _glesys_get_domain
# Returns:
#  _glesys_domain=example.com
#  _glesys_host=sub
_glesys_get_domain() {
  _glesys_domain="$(echo $fulldomain | rev | cut -d . -f 1,2 | rev)"
  _glesys_host="$(echo $fulldomain | rev | cut -d . -f 3- | rev)"

  if [ -z "$_glesys_domain" ]; then
    _err "Error extracting the domain."
    return 1
  fi

  _debug "fulldomain: $fulldomain, domain: $_glesys_domain, host: $_glesys_host"

  return 0
}

# Usage:
#  _glesys_rest body path
# Returns:
#  _response
_glesys_rest() {
  Glesys_User="$(_readaccountconf_mutable Glesys_User)"
  Glesys_Token="$(_readaccountconf_mutable Glesys_Token)"
  _realm="$(printf "%s" "$Glesys_User:$Glesys_Token" | _base64)"
  export _H1="Authorization: Basic $_realm"
  export _H2="Content-Type: application/json"
  _response=$(_post "$1" "https://api.glesys.com/$2")

  _code=$(echo "$_response" | jq .response.status.code)

  if [ "$_code" != "200" ]; then
    _err "Bad response: $response"
    return 1
  fi

  return 0
}
