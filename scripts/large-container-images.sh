#!/usr/bin/env bash

echo "Listing unique container images by size (Largest First):"
echo "--------------------------------------------------------"
printf "%-15s %-60s\n" "SIZE" "IMAGE NAME"
echo "--------------------------------------------------------"

# Get image data from all nodes
# sort -u --> unique
# sort -rnk2 --> sorts by bytes before converting to MB/GB
kubectl get nodes -o json | jq -r '.items[].status.images[] | "\(.names[0]) \(.sizeBytes)"' | \
sort -u -k1,1 | \
sort -rnk2 | \
awk '{
    split("B KB MB GB TB", unit);
    i=1; s=$2;
    while (s>=1024 && i<5) { s/=1024; i++ }
    # Formatting: Size with unit first, then the image name
    printf "%-15s %-60s\n", sprintf("%.2f %s", s, unit[i]), $1
}'