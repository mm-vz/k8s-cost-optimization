#!/bin/bash

echo "Checking namespaces with no running pods..."

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
    pod_count=$(kubectl get pods -n $ns --no-headers 2>/dev/null | wc -l)

    if [ "$pod_count" -eq 0 ]; then
        echo "Idle namespace: $ns"
    fi
done
