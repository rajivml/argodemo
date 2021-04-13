#!/bin/bash
########
# Utils module for different script functions
########

set -e

DIR=.
GREEN='\033[0;32m'
BLUE='\033[0;94m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function error() {
  echo -e "${RED}[ERROR][$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}\n" 1>&2
  exit 1
}

function info() {
  echo "[INFO] [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

function warn() {
  echo -e "${YELLOW}[WARN][$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}\n" 1>&2
}

success() {
    echo -e "${GREEN}✔ [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}\n" 1>&2
}

log_step() {
    echo -e "${BLUE}⚙  [$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}\n" 1>&2
}


function display_usage() {
  echo "usage: $(basename "$0") [-hd] -i infile -o outfile"
  echo "  -d          Run in debug"
  echo "  -h          Display help"
  echo "  -i infile   Specify input json file"
  echo "  -o outfile  Specify output json file"
}

########
# Parse command line arguments. Exit if illegal arguments are passed
# Arguments:
#   1: String to check
#   2: Error message
# Outputs:
#   INFILE and OUTFILE are initialized with their respective values
########
function exit_if_string_empty() {
  if [[ -z "$1" ]]; then
    error "$2"
  fi
}

########
# Parse command line arguments. Exit if illegal arguments are passed
# Globals:
#   INFILE
#   OUTFILE
# Outputs:
#   INFILE and OUTFILE are initialized with their respective values
########
function parse_args() {
  INFILE=""
  OUTFILE=""
  while getopts 'hdi:o:' flag "$@"; do
    case "${flag}" in
    d)
      info "Running in debug"
      set -x
      ;;
    i)
      info "Using input parameters file: ${OPTARG}"
      INFILE=${OPTARG}
      ;;
    h)
      display_usage
      exit 0
      ;;
    o)
      info "Using output parameters file: ${OPTARG}"
      OUTFILE=${OPTARG}
      ;;
    :)
      error "Invalid option: ${OPTARG} requires an argument."
      ;;
    *)
      error "Unexpected option ${flag}"
      ;;
    esac
  done
  if [[ -z "${INFILE}" || -z "${OUTFILE}" ]]; then
    display_usage
    error "Mandatory parameters not found"
  fi
  if [[ ! -f "${INFILE}" ]]; then
    error "File ${INFILE} not found"
  fi
  shift $((OPTIND - 1))
}

########
# Load OS-specific utils.sh
########
function load_os_utils() {
  # shellcheck disable=SC1091
  . /etc/os-release
  local MODULES_DIR=$1
  OS_ID="$ID"
  if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
    # shellcheck disable=SC1090
    source "$MODULES_DIR/debian-utils.sh"
  elif [ "$OS_ID" == "rhel" ]; then
    # shellcheck disable=SC1090
    source "$MODULES_DIR/rhel-utils.sh"
  else
    warn "OS not supported. Skipping OS-specific module loading."
  fi
}

########
# Check if package is installed or command is present
# Uses check_package_installed from os-specific modules loaded above
########
function check_package_or_command() {
  local COMMAND_EXISTS=1
  local PACKAGE_EXISTS=1
  local PATHS
  local IFS=':'
  PATHS="$(whereis "$1")"
  # shellcheck disable=SC2162
  read -a PATHARR <<<"$PATHS"
  if [ ${#PATHARR[@]} -gt "1" ]; then
    COMMAND_EXISTS=0
  fi
  check_package_installed "$1"
  PACKAGE_EXISTS=$?
  if [ $PACKAGE_EXISTS == 0 ] || [ $COMMAND_EXISTS == 0 ]; then
    return 0
  else
    return 1
  fi
}

########
# Check whether a list of packages and/or commands are available
# Usage:
# required_pkgs=(jq curl)
# check_required_packages_and_commands ${required_pkgs[@]}
########
function check_required_packages_and_commands() {
  local required_pkgs=("$@")
  local missing_pkgs=""
  for pkg in "${required_pkgs[@]}"; do
    local package_or_command_exists
    check_package_or_command "$pkg"
    package_or_command_exists=$?
    if [ $package_or_command_exists == 1 ]; then
      missing_pkgs+=" $pkg"
    fi
  done
  if [ -n "$missing_pkgs" ]; then
    error "The following packages and/or commands are not available:$missing_pkgs. Please install them and try again."
  fi
}

########
# Get value from config json
# Globals:
#   INFILE
# Arguments:
#   json_path
# Outputs:
#   Returns the value or exits if not found
########
function get_json_value() {
  local json_path="$1"
  local value

  if ! value="$(jq -er "${json_path}" < "${INFILE}")"; then
    error "${json_path} not found in input file"
  fi

  echo "$value"
}

#####
# Open Port Forward to service or pod
# To use:
# openport argocd service/argocd-server 443
#####
function openport() {
    local try=0
    local maxtry=30
    local PORTFORWARD_PORT=""
    local NAMESPACE=$1
    local ENDPOINT=$2
    local PORT=$3
    kubectl port-forward -n "$NAMESPACE" "$ENDPOINT" ":$PORT" >/dev/null &
    while ((try != maxtry)) && [[ -z $PORTFORWARD_PORT ]] ; do
        try=$((try + 1))
        PORTFORWARD_PORT=$(ss -lp4 | grep "pid=$!" | awk '{print $5}' | awk -F ":" '{print $2}')
        sleep 1
    done
    if [[ -z $PORTFORWARD_PORT ]]; then
        error "Could not open port $PORT to $ENDPOINT in namespace $NAMESPACE"
    else
        echo "$PORTFORWARD_PORT"
    fi
}

#####
# Kill existing kubectl port-forward process based on port
# To use:
# closeport 31842
#####
function closeport() {
    local PORTFORWARD_PORT=$1
    local PID
    PID=$(ss -lp4 | grep "kubectl" | grep "127.0.0.1:$PORTFORWARD_PORT" | awk '{print $7}' | awk -F "pid=" '{print $2}' | awk -F "," '{print $1}')
    kill "$PID"
}

#####
# Check whether an URL is reachable
# To use:
# validate_endpoint ANY_URL
#####
validate_endpoint() {
    response=$(curl -k -i "$1" --insecure)

    if [ -z "$response" ];
    then
      echo "No response received from server for $1. Exiting !!!"
      return 1
    else
      resp_code=$(echo "$response" | grep -v '100 Continue' | grep HTTP | awk '{print $2}')

      if [ "${resp_code}" = "200" ];
      then
        echo "Successfully received response from URL $1: $response"
        return 0
      else
        printf 'Unknown error occurred for %s. Response received: %s \n Exiting !!!' "$1" "$response"
        return 1
      fi
    fi
}
 
#####
# Check db connectivity and db/schema ownership
# To use:
# validate_db_owner "schema" "$SQL_SERVER" "${SQL_USERNAME}"_appmanager "$SQL_PASSWORD" "$DATABASE_NAME" "ai_appmanager"
#####
validate_db_owner() {
  # Checks if the user is db owner
  if [[ "$1" = *"database"* ]];
  then
    response=$(/opt/mssql-tools/bin/sqlcmd -S "$2" -U "$3" -P "$4" -d "$5" -Q "IF IS_ROLEMEMBER ('db_owner') = 1 BEGIN PRINT 'dbo' END")
  else
    response=$(/opt/mssql-tools/bin/sqlcmd -S "$2" -U "$3" -P "$4" -d "$5" -Q "IF (IS_ROLEMEMBER ('db_owner') = 1 OR IS_ROLEMEMBER ('db_ddladmin') = 1) and SCHEMA_NAME() = '$6' BEGIN PRINT 'dbo' END")
  fi

  if [[ "${response}" = *"dbo"* ]]; then
    return 0
  else
    return 1
  fi
}

########
# Discovers public and private IP of the machine
# Outputs:
#   PRIVATE_ADDRESS and PUBLIC_ADDRESS variables will be set
########
function discover_ip_addresses() {
  #discover unix machine distribution
  discover_public_ip
  discover_private_ip
}

########
# Discovers Private IP of the machine
# Outputs:
#   PRIVATE_ADDRESS variable will be set
########
function discover_private_ip() {
  #PRIVATE_ADDRESS=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
  PRIVATE_ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

  #This is needed on k8s 1.18.x as $PRIVATE_ADDRESS is found to have a newline
  PRIVATE_ADDRESS=$(echo "$PRIVATE_ADDRESS" | tr -d '\n')
}

########
# Discovers public address of the machine, if it's airgap environment, then private address will be assigned to PUBLIC_ADDRESS variable
# Outputs:
#   PUBLIC_ADDRESS variable will be set
########
discover_public_ip() {
  PUBLIC_ADDRESS=$(dig +short myip.opendns.com @resolver1.opendns.com)

  if [ -z "$PUBLIC_ADDRESS" ]
  then
    discover_private_ip
    PUBLIC_ADDRESS=$PRIVATE_ADDRESS
  fi
}

function render_yaml() {
  eval "echo \"$(cat $DIR/yaml/"$1")\""
}

function render_yaml_file() {
  eval "echo \"$(cat "$1")\""
}

########
# Run a test every second with a spinner, until it succeeds
# Outputs:
#   Return Exit status of a command
########
function spinner_until() {
  local timeoutSeconds="$1"
  local cmd="$2"
  local args=${@:3}

  if [ -z "$timeoutSeconds" ]; then
      timeoutSeconds=-1
  fi

  local delay=1
  local elapsed=0
  local spinstr='|/-\'

  while ! $cmd "$args"; do
      elapsed=$((elapsed + delay))
      if [ "$timeoutSeconds" -ge 0 ] && [ "$elapsed" -gt "$timeoutSeconds" ]; then
          return 1
      fi
      local temp=${spinstr#?}
      printf " [%c]  " "$spinstr"
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b"
  done
}

########
# Wait till all the pods are in Running state
########
spinner_pod_running() {
  namespace=$1
  podPrefix=$2

  local delay=0.75
  local spinstr='|/-\'
  while ! kubectl -n "$namespace" get pods 2>/dev/null | grep "^$podPrefix" | awk '{ print $3}' | grep '^Running$' > /dev/null ; do
      local temp=${spinstr#?}
      printf " [%c]  " "$spinstr"
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

########
# Check if a kubernetes resource exist
# Outputs:
#   Return True i.e 0 if it exist and return non zero value if it doesn't
########
function kubernetes_resource_exists() {
  local namespace=$1
  local kind=$2
  local name=$3

  kubectl -n "$namespace" get "$kind" "$name" &>/dev/null
}

#Used by docker registry chart to merge resources
function insert_resources() {
  local kustomization_file="$1"
  local resource_file="$2"

  if ! grep -q "resources" "$kustomization_file"; then
      echo "resources:" >> "$kustomization_file"
  fi

  sed -i "/resources.*/a - $resource_file" "$kustomization_file"
}

########
# Validate if Object store properties are set correctly
# Outputs:
#   Return True i.e 0 if they are set correctly and return 1 if doesn't
########
function object_store_exists() {
  if [ -n "$OBJECT_STORE_ACCESS_KEY" ] && \
      [ -n "$OBJECT_STORE_SECRET_KEY" ] && \
      [ -n "$OBJECT_STORE_CLUSTER_IP" ]; then
      return 0
  else
      return 1
  fi
}

########
# Helper method to create bucket under object store
# Outputs:
#   Return non zero value if the bucket creation failed
########
function object_store_create_bucket() {
  if object_store_bucket_exists "$1" ; then
      echo "object store bucket $1 exists"
      return 0
  fi
  if ! _object_store_create_bucket "$1" ; then
      return 1
  fi
  echo "object store bucket $1 created"
}

########
# _ signifies it's a private method, it's a helper method being used by object_store_create_bucket method
########
function _object_store_create_bucket() {
  local bucket=$1
  local acl="x-amz-acl:private"
  local d=$(LC_TIME="en_US.UTF-8" TZ="UTC" date +"%a, %d %b %Y %T %z")
  local string="PUT\n\n\n${d}\n${acl}\n/$bucket"
  local sig=$(echo -en "${string}" | openssl sha1 -hmac "${OBJECT_STORE_SECRET_KEY}" -binary | base64)

  curl -f -X PUT  \
      --noproxy "*" \
      -H "Host: $OBJECT_STORE_CLUSTER_IP" \
      -H "Date: $d" \
      -H "$acl" \
      -H "Authorization: AWS $OBJECT_STORE_ACCESS_KEY:$sig" \
      "http://$OBJECT_STORE_CLUSTER_IP/$bucket" >/dev/null
}

########
# Helper method to check if a bucket already exists under ceph
# Outputs:
#   Return non zero value if the call fails
########
function object_store_bucket_exists() {
  local bucket=$1
  local acl="x-amz-acl:private"
  local d=$(LC_TIME="en_US.UTF-8" TZ="UTC" date +"%a, %d %b %Y %T %z")
  local string="HEAD\n\n\n${d}\n${acl}\n/$bucket"
  local sig=$(echo -en "${string}" | openssl sha1 -hmac "${OBJECT_STORE_SECRET_KEY}" -binary | base64)

  curl -f -I \
      --noproxy "*" \
      -H "Host: $OBJECT_STORE_CLUSTER_IP" \
      -H "Date: $d" \
      -H "$acl" \
      -H "Authorization: AWS $OBJECT_STORE_ACCESS_KEY:$sig" \
      "http://$OBJECT_STORE_CLUSTER_IP/$bucket" &>/dev/null
}

############
# Helper method to fetch docker_registry_ip
# Outputs:
#   DOCKER_REGISTRY_IP will be set
############
DOCKER_REGISTRY_IP=
function discover_docker_private_registry() {
   DOCKER_REGISTRY_IP=$(kubectl -n docker-registry get svc registry -ojsonpath='{.spec.clusterIP}')
}


############
# Helper method to verify if the script is invoked with root user or not
############
function require_root_user() {
  local user="$(id -un 2>/dev/null || true)"
  if [ "$user" != "root" ]; then
      error "Error: this installer needs to be run as root."
  fi
}

###############
# Helper method to patch longhorn storage class as default storage class so that no other changes are required from service owners to provision PVC's
###############
function patch_default_storage_class() { 
  kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
}

###############
# If the helm release is in failed or pending-install state then un-install that release before proceeding with an install/upgrade
# Arguments:
#   releaseName
#   namespace
###############
function helm_uninstall_failed_release() {
  local releaseName=$1
  local namespace=$2

  if [ -z "$releaseName" ]; then
      error "releaseName argument is missing"
  fi

  if [ -z "$namespace" ]; then
      error "namespace argument is missing"
  fi

  target_release_name=$(helm list --all-namespaces -a | grep "$releaseName" | grep -E -- 'pending-install|failed|pending-upgrade' | cut -d ' ' -f 1)

  if [ -n "$target_release_name" ]
  then
    warn "Previous helm deployment: $target_release_name is in failed state, un-installing the same"
    helm uninstall "$target_release_name" -n "$namespace"
  fi
}

###############
# Validate if the certificate is in ready state, if not then identify the reason for failure
# Arguments:
#   namespace
#   cert_name
###############
function validate_certificate_status() {
  local namespace=$1
  local cert_name=$2

  if [ -z "$namespace" ]; then
      error "releaseName argument is missing"
  fi

  if [ -z "$cert_name" ]; then
      error "cert_name argument is missing"
  fi

  counter=1
  cert_creation_status="False"

  while [[ $counter -le 20 && "$cert_creation_status" = "False" ]];
  do
    cert_creation_status=$(kubectl -n "$namespace" get certificate "$cert_name" -o jsonpath='{.status.conditions[0].status}')
    if [ "$cert_creation_status" = "True" ]; then
      echo "Certificate is in ready status"
    else
      echo "Certificate not in ready status yet, sleep for 10 more seconds"
      echo "${counter} iteration check for certificate ready status"
      sleep 10
    fi
    counter=$((counter+1))
  done

  if [ $counter -gt 20 ];
  then
    echo "Certification creation failed !! Exiting "
    cert_failure_reason=$(kubectl -n "$namespace" get certificaterequest -o json | jq -r '.items[0].status.conditions[0].message')
    echo "Cert Creation request failed with error: $cert_failure_reason"
    cert_failure_reason=$(kubectl -n "$namespace" get order -o json | jq -r '.items[0].status.reason')
    echo "Cert Order request failed with error: $cert_failure_reason"
    exit 1
  fi
}

###############
# Wait till the rollout is successfull
# Arguments:
#   namespace
#   object_type (deployment, statefulset etc)
###############
function wait_till_rollout() {
  local namespace=$1
  local object_type=$2
  local app_label=$3

  if [ -z "$namespace" ]; then
      error "namespace argument is missing"
  fi

  if [ -z "$object_type" ]; then
      error "object_type argument is missing"
  fi

  if [ -z "$app_label" ]; then
    deployments=$(kubectl -n "$namespace" get "$object_type" -o name)
  else
    deployments=$(kubectl -n "$namespace" get "$object_type" -l app="$app_label" -o name)
  fi

  for i in $deployments; 
  do 
    if ! kubectl -n "$namespace" rollout status "$i" -w --timeout=600s; 
    then
      echo "$i deployment failed in namespace $namespace. Exiting !!!"
      exit 1
    fi
  done
}

###############
# Label configMap/secret to enable secret/configmap copy to other namespaces
# Arguments:
#   namespace
#   object_type
#   object_name
###############
function label_object() {
  local namespace=$1
  local object_type=$2
  local object_name=$3

  if [ -z "$namespace" ]; then
      error "namespace argument is missing"
  fi

  if [ -z "$object_type" ]; then
      error "object_type argument is missing"
  fi

  if [ -z "$object_name" ]; then
      error "object_type argument is missing"
  fi

  kubectl -n "$namespace" label "$object_type" "$object_name" secret-copier=yes 2>/dev/null || true
}

###############
# Wait till the pods of an particular app are all in Ready status
# Arguments:
#   namespace
#   app_label
###############
function wait_for_pod_ready() {
  local namespace=$1
  local app_label=$2

  if [ -z "$namespace" ]; then
      error "namespace argument is missing"
  fi

  if [ -z "$app_label" ]; then
      error "app_label argument is missing"
  fi

  while [[ $(kubectl -n "$namespace" get pods -l app="$app_label" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "Waiting for app: $app_label to be available" && sleep 5; done
}

###############
# Helper method for rolling restart
# Arguments:
#   namespace
#   object_type
#   object_name
###############
function rollout_restart() {
  local namespace=$1
  local object_type=$2
  local object_name=$3

  if [ -z "$namespace" ]; then
      error "namespace argument is missing"
  fi

  if [ -z "$object_type" ]; then
      error "object_type argument is missing"
  fi

  if [ -z "$object_name" ]; then
      error "object_type argument is missing"
  fi

  kubectl -n "$namespace" rollout restart "$object_type" "$object_name"
  kubectl -n "$namespace" rollout status "$object_type" "$object_name"

  if [ $? -ne 0 ]; 
  then
    error "$object_name restart failed. Exiting !!!"
  fi
}

###############
# Export rook-ceph credentials
###############
function export_ceph_credentials() {
  OBJECT_GATEWAY_INTERNAL_HOST=$(kubectl -n rook-ceph get services/rook-ceph-rgw-rook-ceph -o jsonpath="{.spec.clusterIP}")
  OBJECT_GATEWAY_INTERNAL_PORT=$(kubectl -n rook-ceph get services/rook-ceph-rgw-rook-ceph -o jsonpath="{.spec.ports[0].port}")
  TOOLBOX_POD=$(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o jsonpath="{.items[0].metadata.name}")
  OBJECT_STORE_USER=$(kubectl -n rook-ceph exec -it "${TOOLBOX_POD}" -- sh -c 'radosgw-admin user info --uid=admin')
  OBJECT_STORE_ACCESS_KEY=$(eval echo "$(echo "$OBJECT_STORE_USER" | jq '.keys[0].access_key')")
  OBJECT_STORE_SECRET_KEY=$(eval echo "$(echo "$OBJECT_STORE_USER" | jq '.keys[0].secret_key')")

  export AWS_HOST=$OBJECT_GATEWAY_INTERNAL_HOST
  export AWS_ENDPOINT=$OBJECT_GATEWAY_INTERNAL_HOST:$OBJECT_GATEWAY_INTERNAL_PORT
  export AWS_ACCESS_KEY_ID=$OBJECT_STORE_ACCESS_KEY
  export AWS_SECRET_ACCESS_KEY=$OBJECT_STORE_SECRET_KEY
}
