#!/bin/bash -e

# =============================================================================
# Script to set up a tunnel to a Cloud SQL instance through an instance (ssh tunnel).
# =============================================================================

export CLOUDSDK_PYTHON_SITEPACKAGES=1
local_port=5432

show_help() {
    cat << EOF
Usage: ./cloud-sql-tunnel.sh [OPTIONS]

Options:
  --conn_name   The connection name for the Cloud SQL instance
  --project     The Google Cloud project name
  --zone        The Google Cloud zone
  --instance    The name of the VM instance
  --port        The local port to use for the tunnel (default: 5432)
  -h, --help    Display this help message and exit.

Description:
  This script finds a free port on the specified VM instance and sets up a tunnel to
  the Cloud SQL instance using that port.
EOF
}

if [[ "$#" -eq 0 || "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --conn_name)
            conn_name="$2"
            shift
            ;;
        --project)
            project="$2"
            shift
            ;;
        --zone)
            zone="$2"
            shift
            ;;
        --instance)
            instance="$2"
            shift
            ;;
        --port)
            local_port="$2"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

echo "Checking if the Cloud SQL proxy is installed on the instance..."

gcloud compute ssh "$instance" \
    --project "$project" \
    --zone "$zone" \
    --tunnel-through-iap \
    --command "if [ ! -f cloud-sql-proxy ]; then wget https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.14.0/cloud-sql-proxy.linux.amd64 -O cloud-sql-proxy && chmod +x cloud-sql-proxy; else echo 'Cloud SQL proxy already installed'; fi"

echo "Finding a free port on $instance..."

free_port=$(gcloud compute ssh "$instance" \
    --project "$project" \
    --zone "$zone" \
    --tunnel-through-iap \
    --command "python3 -c 'import socket; s=socket.socket(); s.bind((\"\", 0)); print(s.getsockname()[1]); s.close()'")

echo "Found free port: $free_port"

echo "Setting up tunnel to Cloud SQL on port $local_port..."

gcloud compute ssh "$instance" \
    --project "$project" \
    --zone "$zone" \
    --tunnel-through-iap -- \
      -L $local_port:localhost:"$free_port" \
      "shopt -s huponexit && ./cloud-sql-proxy --port $free_port $conn_name --private-ip"
