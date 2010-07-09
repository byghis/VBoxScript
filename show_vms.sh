#!/bin/bash

vbox=VBoxManage
vms=`$vbox list vms| grep {| sed 's/"//g'`

rm vms.list

for line in $vms 
do
	echo $line|sed 's/{//g'|sed 's/}//g' >> vms.list
done

