#!/usr/bin/bash

#installing helm chart for strimzi
helm repo add strimzi https://strimzi.io/charts/
helm repo update
helm install strimzi-kafka strimzi/strimzi-kafka-operator

#verify strimzi
kubectl get pods
kubectl get crd | grep strimzi


