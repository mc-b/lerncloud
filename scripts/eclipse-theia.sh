#!/bin/bash
#
#   Startet die Eclipse Theia - eine browserbasierte IDE.
#
#   Dateiablage 
#   in Container - /home/project
#   in VM - /home/ubuntu/data/project
#
#   Zugriff auf VM (via Netzwerkadapter Overlay Netzwerk von Kubernetes)
#   - ssh ubuntu@10.244.0.1 
#   Password steht in Einfuehrungseite unter Accessing.
#

cat <<%EOF% | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: eclipse-theia
spec:
 type: LoadBalancer
 ports:
 - port: 3000
   nodePort: 32400   
 selector:
   app: eclipse-theia
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: eclipse-theia
  name: eclipse-theia
spec:
  selector:
    matchLabels:
      app: eclipse-theia
  replicas: 1
  template:
    metadata:
      labels:
        app: eclipse-theia
    spec:
      containers:
      - image: theiaide/theia
        imagePullPolicy: IfNotPresent
        name: eclipse-theia
        ports:
        - containerPort: 3000
        # Volumes im Container
        volumeMounts:
        - mountPath: "/home/project"
          subPath: project           
          name: "eclipse-theia-storage"
      # Volumes in Host
      volumes:
      - name: eclipse-theia-storage
        persistentVolumeClaim:
         claimName: data-claim           
%EOF%
     