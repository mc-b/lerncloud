#!/bin/bash
#
#   Installiert die Erweiterung k-native (Serverless, FAAS) fuer Kubernetes
#

# Serving
sudo microk8s kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.1/serving-crds.yaml
sudo microk8s kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.14.1/serving-core.yaml    
sudo microk8s kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.14.0/kourier.yaml
sudo microk8s kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
# sudo microk8s kubectl patch configmap/config-domain --namespace knative-serving --type merge --patch '{"data":{"microk8s.mshome.net":""}}'  

# Eventing
sudo microk8s kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.14.2/eventing-crds.yaml
sudo microk8s kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.14.2/eventing-core.yaml

# InMemory Channel
sudo microk8s kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.14.2/in-memory-channel.yaml

# InMemory Broker
sudo microk8s kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.14.4/mt-channel-broker.yaml

cat <<EOF | sudo microk8s kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-br-defaults
  namespace: knative-eventing
data:
  default-br-config: |
    # This is the cluster-wide default broker channel.
    clusterDefault:
      brokerClass: MTChannelBasedBroker
      apiVersion: v1
      kind: ConfigMap
      name: imc-channel
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: imc-channel
  namespace: knative-eventing
data:
  channel-template-spec: |
    apiVersion: messaging.knative.dev/v1
    kind: InMemoryChannel
EOF

# Kafka Channel
# sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-controller.yaml
# sudo microk8s kubectl apply -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.5/eventing-kafka-channel.yaml
# Kafka Broker
# sudo microk8s kubectl delete -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-controller.yaml
# sudo microk8s kubectl delete -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-broker.yaml
# sudo microk8s kubectl delete -f https://github.com/knative-extensions/eventing-kafka-broker/releases/download/knative-v1.14.6/eventing-kafka-sink.yaml

# CLI
sudo curl -o /usr/local/bin/kn -sL https://github.com/knative/client/releases/download/knative-v1.14.0/kn-linux-amd64
sudo chmod +x /usr/local/bin/kn 
