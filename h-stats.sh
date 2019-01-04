#!/usr/bin/env bash

#######################
# Functions
#######################


get_cards_hashes(){
	# hs is global
	hs=''
	for (( i=0; i < ${GPU_COUNT_NVIDIA}; i++ )); do
		hs[$i]=''
		local MHS=`cat $LOG_NAME | grep -a "GPU:$(echo $i)" | tail -n1`
		hs[$i]=`echo $MHS | cut -d " " -f9 | cut -d "/" -f1`
	done
}

get_nvidia_cards_temp(){
	echo $(jq -c "[.temp$nvidia_indexes_array]" <<< $gpu_stats)
}

get_nvidia_cards_fan(){
	echo $(jq -c "[.fan$nvidia_indexes_array]" <<< $gpu_stats)
}

get_miner_uptime(){
	local tmp=$(ps -p `pgrep $CUSTOM_NAME` -o lstart=)
	local start=$(date +%s -d "$tmp")
        local now=$(date +%s)
        echo $((now - start))
}

get_total_hashes(){
        # khs is global
        local MHS=`cat $LOG_NAME | grep -a "Total: " | tail -n1`
	echo $MHS | cut -d " " -f6 | cut -d "/" -f1
}



#######################
# MAIN script body
#######################

. /hive/miners/custom/$CUSTOM_MINER/h-manifest.conf
local LOG_NAME="$CUSTOM_LOG_BASENAME.log"

[[ -z $GPU_COUNT_NVIDIA ]] &&
	GPU_COUNT_NVIDIA=`gpu-detect NVIDIA`



# Calc log freshness by logfile timestamp since no time entries in log
lastUpdate="$(stat -c %Y $LOG_NAME)"
now="$(date +%s)"
local diffTime="${now}"
let diffTime="${now}-${lastUpdate}"
local maxDelay=60

# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then
	local hs=
	get_cards_hashes			# hashes array
	local hs_units='hs'			# hashes units
	local temp=$(get_nvidia_cards_temp)	# cards temp
	local fan=$(get_nvidia_cards_fan)	# cards fan
	local uptime=$(get_miner_uptime)	# miner uptime
	local algo="equihash 150/5"			# algo

	# A/R shares by pool
#	local ac=$(get_miner_shares_ac)
#	local rj=$(get_miner_shares_rj)

	# make JSON
	stats=$(jq -nc \
				--argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
				--arg hs_units "$hs_units" \
				--argjson temp "$temp" \
				--argjson fan "$fan" \
				--arg uptime "$uptime" \
				--arg algo "$algo" \
				'{$hs, $hs_units, $temp, $fan, $uptime, $algo}')
	# total hashrate in khs
	khs=$(get_total_hashes)
else
	stats=""
	khs=0
fi

# debug output


#echo temp:  $temp
#echo fan:   $fan
#echo stats: $stats
#echo khs:   $khs
#echo diff: $diffTime
#echo uptime: $uptime
