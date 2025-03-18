#!/bin/bash
#
#   Installiert die Erweiterung k-native (Serverless, FAAS) fuer Kubernetes - ohne Kafka
#

# Serving
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-core.yaml
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.17.0/kourier.yaml
kubectl patch configmap/config-network --namespace knative-serving --type merge --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
# kubectl patch configmap/config-domain --namespace knative-serving --type merge --patch '{"data":{"microk8s.mshome.net":""}}'  

# Eventing
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.17.2/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.17.2/eventing-core.yaml

# InMemory Channel
sudo microk8s kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.14.2/in-memory-channel.yaml

# InMemory Broker
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.17.2/in-memory-channel.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/knative-v1.17.2/mt-channel-broker.yaml
cat <<EOF | kubectl apply -f -
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
      namespace: knative-eventing
    # This allows you to specify different defaults per-namespace,
    # in this case the "some-namespace" namespace will use the Kafka
    # channel ConfigMap by default (only for example, you will need
    # to install kafka also to make use of this).
    namespaceDefaults:
      some-namespace:
        brokerClass: MTChannelBasedBroker
        apiVersion: v1
        kind: ConfigMap
        name: kafka-channel
        namespace: knative-eventing
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
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kafka-channel
  namespace: knative-eventing
data:
  channel-template-spec: |
    apiVersion: messaging.knative.dev/v1alpha1
    kind: KafkaChannel
    spec:
      numPartitions: 3
      replicationFactor: 1        
EOF


# CLI
sudo curl -o /usr/local/bin/kn -sL https://github.com/knative/client/releases/download/knative-v1.17.0/kn-linux-amd64
sudo chmod +x /usr/local/bin/kn 

# Plug-ins
mkdir -p ~/.config/kn/plugins/

curl -o ~/.config/kn/plugins/kn-admin -sL https://github.com/knative-extensions/kn-plugin-admin/releases/download/knative-v1.17.0/kn-admin-linux-amd64
chmod +x ~/.config/kn/plugins/kn-admin

curl -o ~/.config/kn/plugins/kn-event -sL https://github.com/knative-extensions/kn-plugin-event/releases/download/knative-v1.17.1/kn-event-linux-amd64
chmod +x ~/.config/kn/plugins/kn-event

curl -o ~/.config/kn/plugins/kn-func -sL https://github.com/knative/func/releases/download/knative-v1.17.0/func_linux_amd64
chmod +x ~/.config/kn/plugins/kn-func

curl -o ~/.config/kn/plugins/kn-kafka -sL https://github.com/knative-extensions/kn-plugin-source-kafka/releases/download/knative-v1.17.0/kn-source-kafka-linux-amd64
chmod +x ~/.config/kn/plugins/kn-kafka




