#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

run_task() {
    local msg="$1"
    shift
    echo -n -e "${BLUE}[*] $msg...${NC}"
    "$@" > /dev/null 2>&1 &
    local pid=$!
    spinner $pid
    wait $pid
    if [ $? -eq 0 ]; then
        echo -e "\r${GREEN}[+] $msg... Completado.${NC}      "
    else
        echo -e "\r${RED}[-] $msg... Falló.${NC}      "
    fi
}