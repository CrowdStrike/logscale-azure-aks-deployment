#!/usr/bin/bash

H_VER=0.19.0
export HUMIO_OPERATOR_VERSION=$H_VER
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioclusters.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioexternalclusters.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioingesttokens.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioparsers.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humiorepositories.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioviews.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioalerts.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/humio/humio-operator/humio-operator-${HUMIO_OPERATOR_VERSION}/config/crd/bases/core.humio.com_humioactions.yaml
echo "Humio operator installed..."
echo "now install helm chart..."

helm repo add humio-operator https://humio.github.io/humio-operator

echo "helm chart installed..."
helm install humio-operator humio-operator/humio-operator \
  --version=$H_VER \
  --skip-crds
