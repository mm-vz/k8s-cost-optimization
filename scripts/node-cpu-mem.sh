#!/bin/bash

echo "Checking node CPU and memory usage"

kubectl top nodes

echo ""
echo "Nodes with low utilization may be candidates for downsizing."
