#!/bin/bash

vbox=VBoxManage
vms=`$vbox list runningvms| grep {| sed 's/"//g'`

rm runningvms.list

for line in $vms 
do
	echo $line|sed 's/{//g'|sed 's/}//g' >> runningvms.list
done

