#!/bin/bash

echo "Checking for unused Persistent Volumes..."

kubectl get pv | awk '$5=="Released" || $5=="Available" {print $1, $5}'
