#!/bin/bash

DATASOURCES=$(curl -s http://localhost:3000/api/datasources)

if [ -z "$DATASOURCES" ] || [[ "$DATASOURCES" == *"message"*"Unauthorized"* ]]; then
    echo '[{"error": "Could not reach Grafana or authentication is required."}]'
    exit 1
fi

# ==========================================
# 1. DISCOVER ALL SERVICES
# ==========================================
ALL_SERVICES=""

while read -r ds; do
    TYPE=$(echo "$ds" | jq -r '.type')
    DS_UID=$(echo "$ds" | jq -r '.uid')

    if [ "$TYPE" == "loki" ]; then
        RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/loki/api/v1/label/service_name/values")
        FOUND=$(echo "$RES" | jq -r '.data[]?' 2>/dev/null)
        ALL_SERVICES="$ALL_SERVICES\n$FOUND"

    elif [ "$TYPE" == "prometheus" ]; then
        RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/api/v1/label/service_name/values")
        FOUND=$(echo "$RES" | jq -r '.data[]?' 2>/dev/null)
        ALL_SERVICES="$ALL_SERVICES\n$FOUND"

    elif [ "$TYPE" == "tempo" ]; then
        RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/api/search/tag/service.name/values")
        FOUND=$(echo "$RES" | jq -r '.tagValues[]?' 2>/dev/null)
        ALL_SERVICES="$ALL_SERVICES\n$FOUND"
    fi
done < <(echo "$DATASOURCES" | jq -c '.[]')

# Clean up: remove empty lines, sort alphabetically, and remove duplicates
UNIQUE_SERVICES=$(echo -e "$ALL_SERVICES" | sed '/^\s*$/d' | sort -u)

# If no services were found, output empty array and exit gracefully
if [ -z "$UNIQUE_SERVICES" ]; then
    echo '[]'
    exit 0
fi

# ==========================================
# 2. CHECK DATA SOURCES FOR EACH SERVICE
# ==========================================
FINAL_RESULTS=()

# Loop through each discovered service dynamically
while read -r SERVICE_NAME; do

    # Hold the datasource results for this specific service
    SERVICE_DS_RESULTS=()

    while read -r ds; do
        TYPE=$(echo "$ds" | jq -r '.type')
        DS_UID=$(echo "$ds" | jq -r '.uid')
        NAME=$(echo "$ds" | jq -r '.name')
        STATUS=""

        if [ "$TYPE" == "loki" ]; then
            QUERY="{service_name=\"$SERVICE_NAME\"}"
            ENCODED=$(jq -nr --arg q "$QUERY" '$q|@uri')
            RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/loki/api/v1/query_range?query=$ENCODED")

            if [[ "$RES" != *'"result":[]'* ]] && [[ -n "$RES" ]]; then
                STATUS="data_found"
            else
                STATUS="no_data_found"
            fi

        elif [ "$TYPE" == "prometheus" ]; then
            QUERY="{service_name=\"$SERVICE_NAME\"}"
            ENCODED=$(jq -nr --arg q "$QUERY" '$q|@uri')
            RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/api/v1/query?query=$ENCODED")

            if [[ "$RES" != *'"result":[]'* ]] && [[ -n "$RES" ]]; then
                STATUS="data_found"
            else
                STATUS="no_data_found"
            fi

        elif [ "$TYPE" == "tempo" ]; then
            RES=$(curl -s "http://localhost:3000/api/datasources/proxy/uid/$DS_UID/api/search?tags=service.name=$SERVICE_NAME")

            if [[ "$RES" != *'"traces":[]'* ]] && [[ -n "$RES" ]]; then
                STATUS="data_found"
            else
                STATUS="no_data_found"
            fi

        else
            STATUS="not_implemented"
        fi

        # Create a JSON object for this specific datasource status
        DS_OBJ=$(jq -n \
            --arg name "$NAME" \
            --arg status "$STATUS" \
            '{name: $name, status: $status}')

        SERVICE_DS_RESULTS+=("$DS_OBJ")

    done < <(echo "$DATASOURCES" | jq -c '.[]')

    # Convert the array of datasource statuses into a JSON array
    DS_ARRAY=$(printf '%s\n' "${SERVICE_DS_RESULTS[@]}" | jq -s '.')

    # Create the final JSON object mapping the service name to its datasource statuses
    SVC_OBJ=$(jq -n \
        --arg svc "$SERVICE_NAME" \
        --argjson ds "$DS_ARRAY" \
        '{service: $svc, datasources: $ds}')

    FINAL_RESULTS+=("$SVC_OBJ")

done <<< "$UNIQUE_SERVICES"

# Output the final nested JSON structure
printf '%s\n' "${FINAL_RESULTS[@]}" | jq -s '.'
