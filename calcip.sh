#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Función para convertir IP a número
ip_to_int() {
    local IFS=.
    read -r a b c d <<< "$1"
    echo "$(((a << 24) + (b << 16) + (c << 8) + d))"
}

# Función para convertir número a IP
int_to_ip() {
    local ui32=$1; shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo "$ip"
}

# Función para calcular la máscara de red a partir del CIDR
cidr_to_netmask() {
    local cidr=$1
    local mask=$((0xffffffff << (32 - cidr)))
    int_to_ip $mask
}

# Función para determinar la clase de la dirección IP
get_ip_class() {
    local first_octet=$(echo $1 | cut -d. -f1)
    if (( first_octet < 128 )); then
        echo "A"
    elif (( first_octet < 192 )); then
        echo "B"
    elif (( first_octet < 224 )); then
        echo "C"
    elif (( first_octet < 240 )); then
        echo "D"
    else
        echo "E"
    fi
}

# Verificación de argumentos
if [ $# -ne 1 ] || ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
    echo "Uso: $0 <IP/CIDR>"
    exit 1
fi

IP=$(echo $1 | cut -d/ -f1)
CIDR=$(echo $1 | cut -d/ -f2)

# Convertir IP y CIDR a enteros
IP_INT=$(ip_to_int $IP)
NETMASK_INT=$((0xffffffff << (32 - CIDR)))

# Calcular Network ID, Broadcast y Netmask
NETWORK_ID_INT=$((IP_INT & NETMASK_INT))
BROADCAST_INT=$((NETWORK_ID_INT | (0xffffffff ^ NETMASK_INT)))

# Convertir de nuevo a formato IP
NETWORK_ID=$(int_to_ip $NETWORK_ID_INT)
BROADCAST=$(int_to_ip $BROADCAST_INT)
NETMASK=$(cidr_to_netmask $CIDR)
HOSTS=$((2 ** (32 - CIDR) - 2))

# Determinar la clase de la dirección IP
IP_CLASS=$(get_ip_class $IP)

# Mostrar resultados
echo -e "\n\n${purpleColour}Network ID:${endColour}${yellowColour} $NETWORK_ID${endColour}"
echo -e "${purpleColour}Netmask:${endColour}${yellowColour} $NETMASK${endColour}"
echo -e "${purpleColour}Broadcast:${endColour}${yellowColour} $BROADCAST${endColour}"
echo -e "${purpleColour}Hosts disponibles:${endColour}${yellowColour} $HOSTS${endColour}\n"
echo -e "${purpleColour}Clase de IP:${endColour}${yellowColour} $IP_CLASS${endColour}\n"
