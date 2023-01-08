#!/bin/bash
#
#   Docker in Docker mit geoeffnetem Port 2375 gegen aussen, ohne SSL
#

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: dind
  labels:
    app: dind
    group: docker
    tier: backend
spec:
  ports:
  - port: 2375
    protocol: TCP
  selector:
    app: dind
  clusterIP: None     
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dind
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dind
  template:
    metadata:
      labels:
        app: dind
        group: docker
        tier: backend
    spec:
      containers:
      - name: dind
        image: registry.gitlab.com/mc-b/misegr/docker/20-dind
        imagePullPolicy: IfNotPresent
        command: [ "dockerd" ]
        args: [ "--host=tcp://0.0.0.0:2375" ]
        ports:
        - containerPort: 2375
          hostPort: 2375
          name: dind
        - containerPort: 8080
          hostPort: 8080
        - containerPort: 8081
          hostPort: 8081
        - containerPort: 8082
          hostPort: 8082
        - containerPort: 8083
          hostPort: 8083
        - containerPort: 8084
          hostPort: 8084   
        - containerPort: 8085
          hostPort: 8085
        - containerPort: 8086
          hostPort: 8086
        - containerPort: 8087
          hostPort: 8087
        - containerPort: 8088
          hostPort: 8088
        - containerPort: 8089
          hostPort: 8089                                       
        securityContext:
         privileged: true          
EOF


         