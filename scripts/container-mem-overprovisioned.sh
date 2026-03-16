#!/usr/bin/env bash

mem_ratio=${1:-3}

if ! [[ "$mem_ratio" =~ ^[0-9]+$ ]]; then
    echo "Error: Argument must be a positive integer."
    echo "Usage: $0 [threshold_number]"
    exit 1
fi

# needed for calculations
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' is not installed. Please install it to run this script."
    exit 1
fi

echo "Detecting overprovisioned containers (wtih ratio > $mem_ratio:1 requested:usage)..."
echo "------------------------------------------------------------------------------------------------"
printf "%-20s %-12s %-12s %-10s %-25s %-30s\n" "NAMESPACE" "REQ(Mi)" "USE(Mi)" "RATIO" "CONTAINER" "POD"
echo "------------------------------------------------------------------------------------------------"

kubectl top pods -A --no-headers | while read ns pod cpu mem; do

    # use Mi
    mem_usage=$(echo $mem | sed 's/Mi//; s/Ki/*0.0009765625/' | bc -l)

    # skip 0 usage
    if (( $(echo "$mem_usage <= 0.01" | bc -l) )); then continue; fi

    # each container memory
    kubectl get pod "$pod" -n "$ns" -o json | jq -r '.spec.containers[] | "\(.name) \(.resources.requests.memory // "0")"' | while read cname crequest; do

        # using Mi
        req_val=$(echo $crequest | sed 's/Mi//; s/Ki/*0.0009765625/; s/null/0/' | bc -l)

        if (( $(echo "$req_val > 0" | bc -l) )); then
            # request:usage ratio
            ratio=$(echo "$req_val / $mem_usage" | bc -l)

            # filter for ratio > $mem_ratio
            if (( $(echo "$ratio > $mem_ratio" | bc -l) )); then
                printf "%-20s %-12.2f %-12.2f %-10.2f %-25s %-30s\n" "$ns" "$req_val" "$mem_usage" "$ratio" "$cname" "$pod"
            fi
        fi
    done
done
