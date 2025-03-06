#!/bin/zsh

show_icon=false
show_temp=false
show_mem_usage_p=false
show_mem_usage_f=false

usage() {
    echo "Usage: $0 [--icon|-i] [--temp|-t] [--mem-usage-p|-m] [--mem-usage-f|-M] [--help|-h]"
    echo "Prints the percentage of GPU usage. Requires nvidia-smi."
    echo "Options:"
    echo "  --icon, -i         Include an icon in the output."
    echo "  --temp, -t         Include the GPU temperature in the output."
    echo "  --mem-usage-p, -m    Include the GPU memory usage as a percent in the output."
    echo "  --mem-usage-f, -M    Include the GPU memory usage as a fraction in the output."
    echo "  --help, -h         Display this help message."
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --icon|-i) show_icon=true ;;
        --temp|-t) show_temp=true ;;
        --mem-usage-p|-m) show_mem_usage_p=true ;;
        --mem-usage-f|-M) show_mem_usage_f=true ;;
        --help|-h) usage ;;
        *) usage ;;
    esac
    shift
done

if ! nvidia-smi | grep -q "Driver Version:"; then
    if $show_icon; then
        echo "󰢮 GPU ERROR"
    else
        echo "GPU ERROR"
    fi
    exit 1
fi

if $show_temp; then
    gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | awk '{print $1}')
fi

output=""

if $show_icon; then
    output+="󰢮 "
fi

output+=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}')

if $show_temp; then
    output+=" "
    output+=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | awk '{print $1}')
fi

if $show_mem_usage_p; then
    

echo "$output"
gpu_mem_usage=$(nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits | awk '{print $1}')
gpu_mem_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{print $1}')
gpu_mem_used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | awk '{print $1}')
