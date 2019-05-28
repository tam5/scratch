#!/usr/bin/env bash

set -o pipefail
. ./chalk.sh
. ./utils.sh
. ./spinner.sh
lay_traps

#
# show help text
#
usage=$(
    show_description "Upload a bunch of files to realtime api"
    show_usage "bash realtime-api-test.sh [options]"
    show_option_flags_first "-h, --help                      "; show_option_text "Display this help message"
    show_option_flags       "-u, --username                  "; show_option_text "Platform username"
    show_option_flags       "-p, --password                  "; show_option_text "Platform password"
    show_option_flags       "-s, --refId                     "; show_option_text "The refId of the segment"
    show_option_flags       "-a, --action                    "; show_option_text "The action to perform (add/remove)"
    show_option_flags       "-f, --file                      "; show_option_text "The file to upload"
    show_option_flags       "-T, --type                      "; show_option_text "The hash type"
    show_option_flags       "-r, --requests-per-second       "; show_option_text "Number of requests per second"
    show_option_flags       "-t, --total-requests            "; show_option_text "Total number of requests to make"
)

for arg in "$@"; do
  shift
  case "$arg" in
    "--help")                set -- "$@" "-h" ;;
    "--username")            set -- "$@" "-u" ;;
    "--password")            set -- "$@" "-p" ;;
    "--refId")               set -- "$@" "-s" ;;
    "--action")              set -- "$@" "-a" ;;
    "--file")                set -- "$@" "-f" ;;
    "--requests-per-second") set -- "$@" "-r" ;;
    "--total-requests")      set -- "$@" "-t" ;;
    "--type")                set -- "$@" "-T" ;;
    *)                       set -- "$@" "$arg"
  esac
done

while getopts ':hu:p:s:a:f:r:t:T:' option; do
  case "$option" in
    h) echo "$usage" exit ;;
    u) username=($(echo $OPTARG | sed 's/=//g')) ;;
    p) password=($(echo $OPTARG | sed 's/=//g')) ;;
    s) ref_id=($(echo $OPTARG | sed 's/=//g')) ;;
    a) action=($(echo $OPTARG | sed 's/=//g')) ;;
    f) file_path=($(echo $OPTARG | sed 's/=//g')) ;;
    r) requests_per_second=($(echo $OPTARG | sed 's/=//g')) ;;
    t) total_requests=($(echo $OPTARG | sed 's/=//g')) ;;
    T) type=($(echo $OPTARG | sed 's/=//g')) ;;
   \?) echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

for x in username password ref_id action file_path requests_per_second total_requests type; do
    if [ -z "${!x}" ]; then
       print_color red "Missing required parameter $x."
       missing=true
    fi
done

if [ $missing ]; then exit 1; fi

host="https://qa-merlin.liveintenteng.com"
token=$(curl -s -XPOST "$host/login" -d "{ \"username\": \"$username\", \"password\": \"$password\" }" -H 'Content-Type: application/json' | jq -r '.token')

request_counter=0
while [[ $request_counter -lt $total_requests ]]; do
    time curl -XPOST "$host/realtime/audience/$ref_id?type=$type" -d "$(cat $file_path)" -H "Authorization: bearer $token" -H 'Content-Type: text/plain'

    request_counter=$(($request_counter + 1))
    sleep $(echo "1 / $requests_per_second" | bc -l)
done
