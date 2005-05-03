# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../iptables/rocknet_iptables.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---

iptables_init_if() {
	if isfirst "iptables_$if"; then
		addcode up   1 1 "iptables -N firewall_$if"
		addcode up   1 2 "iptables -A INPUT -i $if -j firewall_$if"
		addcode up   1 3 "iptables -A firewall_$if `
			`-m state --state ESTABLISHED,RELATED -j ACCEPT"

		addcode down 1 3 "iptables -F firewall_$if"
		addcode down 1 2 "iptables -D INPUT -i $if -j firewall_$if"
		addcode down 1 1 "iptables -X firewall_$if"
	fi
}

iptables_parse_conditions() {
	iptables_cond=""
	while [ -n "$1" ]
	do
		case "$1" in
		    all)
			shift
			;;
		    tcp|udp)
			iptables_cond="$iptables_cond -p $1 --dport $2"
			shift; shift
			;;
		    icmp)
			iptables_cond="$iptables_cond -p icmp --icmp-type $2"
			shift; shift
			;;
		    ip)
			iptables_cond="$iptables_cond -s $2"
			shift; shift
			;;
		    *)
			error "Unkown accept/reject/drop condition: $1"
			shift
		esac
	done
}

public_accept() {
	iptables_parse_conditions "$@"
	addcode up 1 5 "iptables -A firewall_$if $iptables_cond -j ACCEPT"
	iptables_init_if
}

public_reject() {
	iptables_parse_conditions "$@"
	addcode up 1 5 "iptables -A firewall_$if $iptables_cond -j REJECT"
	iptables_init_if
}

public_drop() {
	iptables_parse_conditions "$@"
	addcode up 1 5 "iptables -A firewall_$if $iptables_cond -j DROP"
	iptables_init_if
}

public_conduit() {
	# conduit (tcp|udp) port targetip[:targetport]
	#
	local proto=$1 port=$2
	local targetip=$3 targetport=$2

	if [ "${targetip/:/}" != "$targetip" ]; then
		targetport=${targetip#*:}
		targetip=${targetip%:*}
	fi

	addcode up 1 6 "iptables -t nat -A PREROUTING -i $if -p $proto \
		 --dport $port -j DNAT --to $targetip:$targetport"
	addcode up 1 6 "iptables -A FORWARD -i $if -p $proto -d $targetip \
		 --dport $targetport -j ACCEPT"

	iptables_init_if
}

public_clamp_mtu() {
	addcode up 1 6 "iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
	                -j TCPMSS --clamp-mss-to-pmtu"
	addcode down 9 6 "iptables -D FORWARD -p tcp --tcp-flags SYN,RST SYN \
	                  -j TCPMSS --clamp-mss-to-pmtu"
}

public_masquerade() {
	addcode up 1 6 "iptables -t nat -A POSTROUTING -o $if \
	                -j MASQUERADE"
	addcode down 9 6 "iptables -t nat -D POSTROUTING -o $if \
	                  -j MASQUERADE"
}

