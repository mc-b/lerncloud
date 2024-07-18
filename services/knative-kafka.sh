#!/bin/bash
#
#   Installiert die Erweiterung k-native (Serverless, FAAS), mit Kafka, fuer Kubernetes.
#   ACHTUNG: zuerst muss knative.sh ausgefuehrt werden!
#

# Kafka Controller
sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-controller.yaml

# Kafka Broker
sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-broker.yaml

# Kafka Channel
sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-channel.yaml

# Kafka Endpoint (sink)
sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-sink.yaml
