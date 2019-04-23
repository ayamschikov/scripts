#!/usr/bin/env bash

usage()
{
  echo "$(basename "$0") -- program to get backup from openshift

  Note that all parameters are required (except '-h' and '-s')
  You can store these parameters in separate file and include it with '-s' option

  where:
    -h  show this help text
    -d  set db name
    -U  set db user name
    -t  set token for login
    -p  set project name
    -P  set pod name (only service name)
    -s  source file with config
    -u  openshift url with port
  "
  exit 2
}

while getopts ':ht:p:P:d:u:s:u:' option; do
  case "$option" in
    h) usage
       ;;
    t) token=$OPTARG
       ;;
    p) project=$OPTARG
       ;;
    P) pod=$OPTARG
       ;;
    d) db=$OPTARG
       ;;
    U) user=$OPTARG
       ;;
    u) url=$OPTARG
       ;;
    s) file=$OPTARG
       ;;
    :) printf "Missing argument for -%s\n\n" "$OPTARG" >&2
       usage
       ;;
   \?) printf "Illegal option: -%s\n\n" "$OPTARG" >&2
       usage
       ;;
  esac
done
shift $((OPTIND - 1))

if [ -n "$file" ] && [ -r "$file" ]; then
  . $file
fi

if [ -z "$token" ] || [ -z "$project" ] || [ -z "$pod" ] || [ -z "$db" ] || [ -z "$user" ] || [ -z "$url" ]; then
  usage
fi

oc login $url --token=$token

if [ $? -eq 0  ]; then
  oc project $project 
  if [ $? -eq 0  ]; then
    POD="$(oc get pods | grep $pod | awk '{print $1}')"
    FILE="$(date '+%s')_backup.sql"
    oc exec $POD -- bash -c "pg_dump -U $user $db" > ./$FILE

    echo "New file created"
    ls $FILE
  fi
fi

exit
