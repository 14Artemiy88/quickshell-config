#!/bin/bash

weather_gismeteo_fetch() {
    local token="$1"
    local endpoint_type="$2"
    local params="$3"
    local expected_type
    case "$endpoint_type" in
        current) expected_type="object" ;;
        forecast|forecast/aggregate) expected_type="array" ;;
        *)
            echo "weather: unsupported Gismeteo endpoint type: $endpoint_type" >&2
            return 1
            ;;
    esac

    # Keep the credential out of curl's process arguments (visible through
    # /proc/*/cmdline on many Linux systems). curl reads the header from stdin;
    # printf is a Bash builtin and the token travels only through the pipe.
    # Gismeteo payloads are small; cap an unexpected or hostile response
    # before jq slurps it into memory. curl returns CURLE_FILESIZE_EXCEEDED
    # when the transfer exceeds this fixed 4 MiB ceiling.
    printf 'X-Gismeteo-Token: %s\n' "$token" |
        curl -sfS \
            --connect-timeout "$WEATHER_CURL_CONNECT_TIMEOUT" \
            --max-time "$WEATHER_CURL_MAX_TIME" \
            --max-filesize 4194304 \
            --header @- \
            "https://api.gismeteo.net/v2/weather/$endpoint_type/4517/$params" |
        # Slurp the HTTP body and publish only a single JSON envelope. Without
        # -s, jq would process concatenated documents independently, allowing
        # one valid trailing response to conceal an earlier invalid document.
        jq -cs --arg expected_type "$expected_type" \
            'if length != 1 then empty
             elif (.[0] | type) != "object" then empty
             else .[0].response
                  | if type == $expected_type then select(length > 0) else empty end
             end'
}
