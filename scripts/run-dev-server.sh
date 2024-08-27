#!/usr/bin/env bash
set -e

cleanup() {
    echo "Cleaning up..."
    kill $mlflow $ui 2>/dev/null
    exit
}

python_preconfigure() {
  if [ ! -d venv ]; then
    python3 -m venv venv
    source venv/bin/activate
    python3 -m pip install --upgrade pip
    python3 -m pip install build setuptools
    python3 -m pip install -e .
  fi
}

ui_preconfigure() {
  if [ ! -d "web-ui/node_modules" ]; then
    pushd web-ui
    yarn install
    popd
  fi
}

wait_server_ready() {
  for backoff in 0 1 1 2 3 5 8 13 21; do
    echo "Waiting for tracking server to be ready..."
    sleep $backoff
    if curl --fail --silent --show-error --output /dev/null $1; then
      echo "Server is ready"
      return 0
    fi
  done
  echo -e "\nFailed to launch tracking server"
  return 1
}

python_preconfigure
source venv/bin/activate
BACKEND_URI=${BACKEND_URI:-"postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_PRIVATE_IP}:5432/${DB_NAME}"}
mlflow server --app-name oidc-auth --host 0.0.0.0 --port 5000 --backend-store-uri ${BACKEND_URI} --default-artifact-root gs://${GCS_BACKEND}
# wait_server_ready localhost:5000/health
ui_preconfigure
# yarn --cwd web-ui watch

trap cleanup SIGINT
