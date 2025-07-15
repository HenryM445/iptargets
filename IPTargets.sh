#!/bin/bash

declare -a ip=$1
declare -a class=$(seq 1 32)
declare -a range=$(echo "$1"|cut -d "/" -f 2)
binnetmask=""
decnetmask=""
ipbin=""
andnet=""
ipbroad=""

function ctrl_c(){
	echo -e "\n Saliendo....\n"
	exit 1
}

function operations(){
	hosts=$((2147483648/(2**($range-1))))
	hosts=$(($hosts-2))

	if [[ $hosts -lt 0 ]];then

		hosts=0
	fi
	return $hosts
}
function binary(){
	firstoctal=$(echo "$ip"|cut -d "." -f1)
	binfirstoctal=$(echo "obase=2;$firstoctal"| bc | xargs printf "%08d\n")	
	secondoctal=$(echo "$ip"|cut -d "." -f2)
	binsecondoctal=$(echo "obase=2;$secondoctal"| bc | xargs printf "%08d\n")
	thirdoctal=$(echo "$ip"|cut -d "." -f3)
	binthirdoctal=$(echo "obase=2;$thirdoctal"| bc |xargs printf "%08d\n")
	fourthoctal=$(echo "$ip" | cut -d "." -f4 | cut -d "/" -f1)
	binfourthoctal=$(echo "obase=2;$fourthoctal"| bc | xargs printf "%08d\n")

	
	ipbin=($binfirstoctal$binsecondoctal$binthirdoctal$binfourthoctal)
}

function netmask(){
	netmaskid=$(echo "$ip"| cut -d '.' -f4| cut -d '/' -f2)
	count=$(echo "32-$netmaskid"|bc)	

	for ((i=1;i<=32;i++)) do
		if [ $i -le $netmaskid ];then
			binnetmask+=1
		else 
			binnetmask+=0
		fi
	done
	part1=$(echo "ibase=2;${binnetmask:0:8}"| bc)
	part2=$(echo "ibase=2;${binnetmask:8:8}"| bc)
	part3=$(echo "ibase=2;${binnetmask:16:8}"| bc)
	part4=$(echo "ibase=2;${binnetmask:24:8}"| bc)
		
	decnetmask=($part1.$part2.$part3.$part4)
	
}

function NetworkID(){

	result=$(echo "$ipbin"| tr -d ".")
	decresult=$((2#$result))
	decbinnetmask=$((2#$binnetmask))
	andnet=$(( $decresult & $decbinnetmask ))
	numero=${#andnet}

	if [ $numero -lt 32 ]; then
		
		netidresolve=$(echo "obase=2;$andnet"| bc | awk '{ printf "%32s\n", $0 }' | tr ' ' '0')	
	fi
		
		for ((i=0;i<=24;i=i+8));do

		if [ $i != 24 ];then
		netidpart+=$(echo "ibase=2;${netidresolve:i:8}"| bc).
		
		else
		netidpart+=$(echo "ibase=2;${netidresolve:i:8}"| bc)
		
		fi
	done
	echo " [+] NetworkID: $netidpart"
}

function broadcast(){
	netmaskid=$(echo "$ip"| cut -d '.' -f4| cut -d '/' -f2)
	broadhalf=$((32-$netmaskid))
	ipbroad=$(echo "${ipbin:0:$netmaskid}")
	
	for ((i=$netmaskid+1;i<=32;i++));do

		ipbroad+=1	
	done	
	


	for ((i=0;i<=24;i=i+8));do
		if [ $i != 24 ];then
		broadpart+=$(echo "ibase=2;${ipbroad:i:8}" | bc).
		 	
		else
		broadpart+=$(echo "ibase=2;${ipbroad:i:8}" | bc)
		fi
	done
	echo " [+] BroadCast Address: $broadpart"

}

function hostMin(){
	hostmin=$(( $andnet+1 ))
	binmin=$(echo "obase=2;$hostmin" | bc)
	bitshost=${#binmin}	
	
	
	if [ $bitshost -lt 32 ];then
		
		hostminbin=$(echo "obase=2;$hostmin"| bc | awk '{ printf "%32s\n", $0 }' | tr ' ' '0')
			
	else
		hostminbin=$binmin

	
	fi
	for (( i=0;i<=24;i=i+8 ));do
		if [ $i != 24 ];then

			hostmindec+=$(echo "ibase=2;${hostminbin:i:8}"| bc).
		else
			hostmindec+=$(echo "ibase=2;${hostminbin:i:8}"| bc)
		fi
	done

	echo " [+] Host Min: $hostmindec"	


}

function hostMax(){
	
	decipbroad=$((2#$ipbroad))
	hostmaxdec=$(($decipbroad-1))
	hostmaxbin=$(echo "obase=2;$hostmaxdec"|bc)
	bitshostmaxbin=${#hostmaxbin}

	if [ $bitshostmaxbin -lt 32 ]; then
	
		hostmaxbin=$(echo "obase=2;$hostmaxdec"| bc | awk '{ printf "%32s\n", $0 }' | tr ' ' '0')
	fi

	for (( i=0;i<=24;i=i+8 ));do
		if [ $i != 24 ];then

			hostmax+=$(echo "ibase=2;${hostmaxbin:i:8}"|bc ).
		else
			hostmax+=$(echo "ibase=2;${hostmaxbin:i:8}"| bc)
		fi
	done 
	echo " [+] Host Max: $hostmax"
	
}

firstoctal=$(echo "$ip"|cut -d "." -f1)
secondoctal=$(echo "$ip"|cut -d "." -f2)
thirdoctal=$(echo "$ip"|cut -d "." -f3)
fourthoctal=$(echo "$ip" | cut -d "." -f4 | cut -d "/" -f1)

points=$(echo "$ip"| grep -o "\." | wc -l)

slash=$(echo "$ip"| grep -o "/" |  wc -l)
letters=$(echo "$ip" | grep -o '[a-zA-Z]'| wc -l)
specialchac=$(echo "$ip" | grep  -o "[^a-zA-Z0-9./]"| wc -l)

if [[ $letters -eq 0 && $points -eq 3 && $slash -eq 1 && $specialchac -eq 0 ]];then

	if [[ $firstoctal -le 255 && $secondoctal -le 255 && $thirdoctal -le 255 && $fourthoctal -le 255 && $range -le 32 ]];then
	operations
	echo -e "\n [+] Number of hosts: $hosts"
	binary
	netmask
	echo " [+] Subnet Mask: $decnetmask"
	NetworkID
	broadcast
	hostMin
	hostMax

	else

	echo -e "\n +++++ INCORRECT IP  +++++"
	fi	
else
	echo -e "\n +++++ WRONG FORMAT +++++"


fi
trap ctrl_c SIGINT
