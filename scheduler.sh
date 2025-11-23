#!/bin/bash

CRON="$PERIOD_CRON_SYNTAX"  # e.g., "*/5 * * * *"
echo "Using CRON syntax: $CRON"

# Function to convert a cron field to a list of minutes/hours/days
parse_field() {
    field="$1"
    min="$2"
    max="$3"
    result=()

    IFS=',' read -ra parts <<< "$field"
    for part in "${parts[@]}"; do
        if [[ "$part" == "*" ]]; then
            for i in $(seq $min $max); do result+=($i); done
        elif [[ "$part" =~ / ]]; then
            base=${part%/*}
            step=${part#*/}

            if [[ "$base" == "*" ]]; then
                start=$min
                end=$max
            elif [[ "$base" =~ - ]]; then
                start=${base%-*}
                end=${base#*-}
            else
                start=$base
                end=$base
            fi

            for i in $(seq $start $step $end); do
                result+=($i)
            done
        elif [[ "$part" =~ - ]]; then
            start=${part%-*}
            end=${part#*-}
            for i in $(seq $start $end); do result+=($i); done
        else
            result+=($part)
        fi
    done

    echo "${result[@]}"
}

# Split cron string
read -r CRON_MIN CRON_HOUR CRON_DOM CRON_MON CRON_DOW <<< "$CRON"

# Precompute lists
MINUTES=($(parse_field "$CRON_MIN" 0 59))
HOURS=($(parse_field "$CRON_HOUR" 0 23))
DOMS=($(parse_field "$CRON_DOM" 1 31))
MONTHS=($(parse_field "$CRON_MON" 1 12))
DOWS=($(parse_field "$CRON_DOW" 0 6))
echo "Scheduled minutes: ${MINUTES[*]}"
echo "Scheduled hours: ${HOURS[*]}"
echo "Scheduled DOMs: ${DOMS[*]}"
echo "Scheduled MONTHs: ${MONTHS[*]}"
echo "Scheduled DOWs: ${DOWS[*]}"

while true; do
    now_min=$(date +%-M)
    now_hour=$(date +%-H)
    now_dom=$(date +%-d)
    now_mon=$(date +%-m)
    now_dow=$(date +%-w)

    run=false
    echo "Current time: $now_hour:$now_min DOM:$now_dom MON:$now_mon DOW:$now_dow"

    # Check if current time matches cron fields
    [[ " ${MINUTES[*]} " =~ " $now_min " ]] && \
    [[ " ${HOURS[*]} " =~ " $now_hour " ]] && \
    [[ " ${DOMS[*]} " =~ " $now_dom " ]] && \
    [[ " ${MONTHS[*]} " =~ " $now_mon " ]] && \
    [[ " ${DOWS[*]} " =~ " $now_dow " ]] && run=true


    $run && /app/run.sh

    sleep 60  # check every minute
done
