#!/bin/bash

# MIT License
#
# Sherver: Pure Bash lightweight web server.
# Copyright (c) 2019 Rémi Ducceschi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

set -efu

# Public: The full request string
declare -g REQUEST_FULL_STRING=''

# Public: Initialize the environment.
#
# This function should always be ran at the top of any scripts. Once this function has
# run, all the following variables will be available:
#
# * `REQUEST_METHOD`
# * `REQUEST_URL`
# * `REQUEST_HEADERS`
# * `REQUEST_BODY`
# * `REQUEST_BODY_PARAMETERS`
# * `URL_BASE`
# * `URL_PARAMETERS`
# * `RESPONSE_HEADERS`
# * `HTTP_RESPONSE`
# * `REQUEST_FULL_STRING`
#
# To do so, ti will read from the standard input the received request, and execute
# `read_request` to initialize everything.
#
# Then, it will export the full request in the environment variable `REQUEST_FULL_STRING`
# so it can always be reexecuted.
#
# This echanism also allows non bash script to have access to the request through the
#environment.
function init_environment() {
  # we set all the needed variables in the environment.
  # this is needed because we can't export associative arrays...

  # Public: The method of the request (GET, POST...)
  declare -g REQUEST_METHOD=''
  # Public: The requested URL
  declare -g REQUEST_URL=''
  # Public: The headers from the request (associative array)
  declare -Ag REQUEST_HEADERS
  # Public: Body of the request (mainly useful for POST)
  declare -g REQUEST_BODY=''
  # Public: parameters of the request, in case of POST with `application/x-www-form-urlencoded`
  # content
  declare -Ag REQUEST_BODY_PARAMETERS
  # Public: The base URL, without the query string if any
  declare -g URL_BASE=''
  # Public: The parameters of the query string if any (in an associative array)
  #
  # See `parse_url()`.
  declare -Ag URL_PARAMETERS
  # Public: The response headers (associative array)
  declare -Ag RESPONSE_HEADERS=(
    [Server]='Sherver'
    [Connection]='close'
    [Cache - Control]='private, max-age=60'
  )
  # Public: Generic HTTP response code with their meaning (associative array)
  declare -rAg HTTP_RESPONSE=(
    [200]='OK'
    [500]='Internal Server Error'
  )

  # if REQUEST_FULL_STRING is empty, we fill it with the input stream and we export it
  if [ -z "$REQUEST_FULL_STRING" ]; then
    read_request true
    export REQUEST_FULL_STRING
  else
    read_request false <<<"$REQUEST_FULL_STRING"
  fi
}

# Public: Parse the given URL to exrtact the base URL and the query string.
#
# Takes an optional parameters: the URL to parse. By default, it will take the content of
# the variable `REQUEST_URL`.
#
# It will store the base of the URL (without query string) in `URL_BASE`.
# It will store all the parameters of the query string in the associative array `URL_PARAMETERS`.
#
# $1 - Optional: URL to parse (default will take content of `REQUEST_URL`)
#
# Examples
#
#    parse_url '/index.sh?test=youpi&answer=42'
#
# will result in
#
#    URL_BASE='/index.sh'
#    URL_PARAMETERS=(
#        ['test']='youpi'
#        ['answer']='42'
#    )
function parse_url() {
  # get base URL and parameters
  local parameters
  IFS='?' read -r URL_BASE parameters <<<"${1:-$REQUEST_URL}"
  # now split parameters
  # first, split `key=value` in an array
  local -a fields
  IFS='&' read -ra fields <<<"$parameters"
  # now we fill URL_PARAMETERS
  local key value
  local -i i
  for ((i = 0; i < ${#fields[@]}; i++)); do
    IFS='=' read -r key value <<<"${fields[i]}"
    URL_PARAMETERS["$key"]="$value"
  done
}

# Internal: Read the client request and set up environment.
#
# **Note:** this method is used by the dispatcher and shouldn't be called manually.
#
# Reads the input stream and fills the following variables (also run `parse_url()`):
#
# * `REQUEST_METHOD`
# * `REQUEST_HTTP_VERSION`
# * `REQUEST_HEADERS`
# * `REQUEST_BODY`
# * `REQUEST_BODY_PARAMETERS`
# * `REQUEST_URL`
# * `URL_BASE`
# * `URL_PARAMETERS`
#
# *Note* that this method is highly inspired by [bashttpd](https://github.com/avleen/bashttpd)
function read_request() {
  local line
  if ! read -r line; then
    exit 1
  fi
  line=${line%%$'\r'}
  REQUEST_FULL_STRING="$line"

  # read URL
  read -r REQUEST_METHOD REQUEST_URL REQUEST_HTTP_VERSION <<<"$line"
  if [ -z "$REQUEST_METHOD" ] || [ -z "$REQUEST_URL" ] || [ -z "$REQUEST_HTTP_VERSION" ]; then
    exit 1
  fi

  if [ "$REQUEST_METHOD" != 'GET' ]; then
    exit 1
  fi
  # fill URL_*
  parse_url "$REQUEST_URL"
}

init_environment

if [[ -v URL_PARAMETERS[ip] ]] && [[ "$REQUEST_URL" == *"/update"* ]]; then
  if bash update.sh "${URL_PARAMETERS[ip]}"; then
    echo OK
  else
    echo KO
  fi
else
  echo KO
fi

exit 0
