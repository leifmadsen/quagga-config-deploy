#!/usr/bin/env bash
bgp_asn=65100
bootstrap_file=bootstrap
inventory_file=inventory
default_network="10.17.66"
network=${1:-$default_network}

echo $network
exit

truncate --size 0 $bootstrap_file
truncate --size 0 $inventory_file


cat >> $bootstrap_file <<EOL
[overcloud]
EOL

cat >> $inventory_file <<EOL
[overcloud:vars]
ansible_ssh_user=heat-admin

[overcloud]
EOL

for host in $(nova list --fields Networks | awk '/ctlplane/ {print $4};' | cut -d'=' -f2); do
	result=`ssh -o StrictHostKeyChecking=no heat-admin@$host "/usr/sbin/ip a s | awk '/inet / {print $2};' | grep '$network' | grep -v '\/32' && hostname -f"`
	hostname=`echo $result | awk '/inet / {print $9};'`
	address=`echo $result | awk '/inet / {print $2};'`
	ip=`echo $address | cut -f1 -d'/'`
	prefix=`echo $address | cut -f2 -d'/'`
	interface=`echo $result | awk '/inet / {print $8};'`
	ansible_interface=`echo $interface | tr - _`

	second_octet=`echo $ip | cut -f2 -d'.'`
	new_ip=`echo -n $ip | cut -f1 -d'.'`
	new_ip+='.'
	new_ip+=$[$second_octet+1]
	new_ip+='.'
	new_ip+=`echo $ip | cut -f3 -d'.'`
	new_ip+='.'
	new_ip+=`echo $ip | cut -f4 -d'.'`

	cat >> $bootstrap_file <<EOL
$hostname ansible_ssh_host=$ip ansible_ssh_user=heat-admin local_prefix=$prefix local_interface=$interface:1 local_ipaddr=$new_ip
EOL


	bgp_asn=$[$bgp_asn+1]

	cat >> $inventory_file <<EOL
$hostname ansible_ssh_host=$new_ip bgp_asn=$bgp_asn base_interface=$interface local_ipaddr=$ip local_prefix=32 del_prefix=$prefix ansible_interface=$ansible_interface
EOL
done
