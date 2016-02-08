#!/usr/bin/env bash
truncate --size 0 bootstrap
truncate --size 0 new_inventory

bgp_asn=65100

cat >> bootstrap <<EOL
[overcloud]
EOL

for host in {23..27}; do
	result=`ssh heat-admin@172.16.0.$host "/usr/sbin/ip a s | awk '/inet / {print $2};' | grep '172.16.0' | grep -v '\/32' && hostname -f"`
	hostname=`echo $result | awk '/inet / {print $9};'`
	address=`echo $result | awk '/inet / {print $2};'`
	ip=`echo $address | cut -f1 -d'/'`
	prefix=`echo $address | cut -f2 -d'/'`
	interface=`echo $result | awk '/inet / {print $8};'`

	second_octet=`echo $ip | cut -f2 -d'.'`
	new_ip=`echo -n $ip | cut -f1 -d'.'`
	new_ip+='.'
	new_ip+=$[$second_octet+1]
	new_ip+='.'
	new_ip+=`echo $ip | cut -f3 -d'.'`
	new_ip+='.'
	new_ip+=`echo $ip | cut -f4 -d'.'`

	cat >> bootstrap <<EOL
$hostname ansible_ssh_host=$ip ansible_ssh_user=heat-admin local_prefix=$prefix local_interface=$interface local_new_ipaddr=$new_ip
EOL


	bgp_asn=$[$bgp_asn+1]

	cat >> new_inventory <<EOL
$hostname ansible_ssh_host=$new_ip bgp_asn=$bgp_asn base_interface=$interface
EOL
done
