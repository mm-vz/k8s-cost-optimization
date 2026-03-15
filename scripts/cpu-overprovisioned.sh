#!/usr/bin/env bash

x_usage=${1:-5}

if ! [[ "$x_usage" =~ ^[0-9]+$ ]]; then
    echo "Error: Argument must be a positive integer."
    echo "Usage: $0 [threshold_number]"
    exit 1
fi

# Header for the table
echo "Detecting pods with overprovisioned CPU requests (>${x_usage}x usage)..."
echo "---------------------------------------------------------------------------"
printf "%-10s %-12s %-40s\n" "CPU (m)" "MEM" "POD (NS/NAME)"
echo "---------------------------------------------------------------------------"

kubectl top pods -A --no-headers | while read ns pod cpu mem; do

    # Strip 'm'
    cpu_usage=$(echo $cpu | sed 's/m//')

    # Ensure cpu_usage is at least 1
    [[ -z "$cpu_usage" || "$cpu_usage" -eq 0 ]] && cpu_usage=1

    # Requested CPU aand sum of all containers in pod
    request=$(kubectl get pod "$pod" -n "$ns" -o json | \
        jq -r '[.spec.containers[].resources.requests.cpu // "0"] |
               map(if type == "string" then (if contains("m") then sub("m";"") else (tonumber * 1000 | tostring) end) else . end | tonumber) | add')

    if [[ $request -gt 0 ]]; then
        # request:usage ratio
        ratio=$((request / cpu_usage))

        # request 5x higher than usage
        if [[ $ratio -ge $x_usage ]]; then
            # Display format: CPU | MEM | POD
            printf "%-10s %-12s %-40s\n" "${request}m" "$mem" "$ns/$pod"
        fi
    fi
done