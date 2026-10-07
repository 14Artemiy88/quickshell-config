#!/bin/bash

weather_gismeteo_fetch() {
    local token="$1"
    local endpoint_type="$2"
    local params="$3"

    curl -sfS \
        --connect-timeout "$WEATHER_CURL_CONNECT_TIMEOUT" \
        --max-time "$WEATHER_CURL_MAX_TIME" \
        -H "X-Gismeteo-Token: $token" \
        "https://api.gismeteo.net/v2/weather/$endpoint_type/4517/$params" |
        jq -c '.response | select(. != null)'
}
