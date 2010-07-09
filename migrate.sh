#!/bin/bash
# 1. Maquina a Migrar : vm1
# 2. Donde Migrar:      pm2

#TODO storage_VBOXMANAGE
#Connect Linux: mount smbclient, Windows ?

#Options

function log() {
    if [ $DEBUG -eq 1 ]; then
        echo $*
    fi
}


VBOXMANAGE="$(which VBoxManage) -q"
DEBUG=1

$VBOXMANAGE startvm $1
sleep 3

log "Starting Teleport VirtualBox"

log "Setting PARAM_VM and PARAM_PM Options"
PARAM_VM_SOURCE_HOSTNAME=$1
#UUID from vm1
PARAM_VM_UUID=`$VBOXMANAGE list runningvms | grep $PARAM_VM_SOURCE_HOSTNAME | awk '{print $2}'|sed 's/{//g'|sed 's/}//g'` 

#Phisical Machines Options
PARAM_PM_SOURCE_HOSTNAME="jaku"
PARAM_PM_SOURCE_IP="10.0.2.10"
PARAM_PM_TARGET_HOSTNAME="new_host"		 
PARAM_PM_TARGET_IP=$2
	
#Settins Options for the Target Virtual Machine	
PARAM_VM_NAME=`$VBOXMANAGE list runningvms| grep $PARAM_VM_UUID| awk '{print $1}'`|sed 's/"//g' # delete the "'s
#Update the new vm hostname
PARAM_VM_NAME=$PARAM_PM_SOURCE_HOSTNAME"."$PARAM_VM_SOURCE_HOSTNAME

log "Getting values from config options from: $PARAM_VM_SOURCE_HOSTNAME"
PARAM_OSTYPE=`$VBOXMANAGE showvminfo $PARAM_VM_UUID|grep "Guest\ OS"|awk {'print $3'}`
PARAM_VM_MEMORY=`$VBOXMANAGE showvminfo $PARAM_VM_UUID |grep Memory |awk '{print $3}'|sed 's/MB//g'`
PARAM_VM_VRAM=`$VBOXMANAGE showvminfo $PARAM_VM_UUID |grep VRAM |awk '{print $3}'|sed 's/MB//g'`
PARAM_VM_HD=`$VBOXMANAGE showvminfo $PARAM_VM_UUID |grep SATA | grep UUID| awk '{print $7}'|sed 's/)//'`


log "Setting vm options for the new host: $PARAM_PM_TARGET_HOSTNAME"

#Create and Register a new Description file Virtual Machine
$VBOXMANAGE createvm --name $PARAM_VM_NAME --ostype $PARAM_OSTYPE --register

#Enable PAE
$VBOXMANAGE modifyvm $PARAM_VM_NAME --pae on

#Enabling Nesting Paging
$VBOXMANAGE modifyvm $PARAM_VM_NAME --nestedpaging on

#Memory
$VBOXMANAGE modifyvm $PARAM_VM_NAME --memory $PARAM_VM_MEMORY

#VRam
$VBOXMANAGE modifyvm $PARAM_VM_NAME --vram $PARAM_VM_VRAM

#Audio Disabled
#DEFAULT OPTION

#Usb Disabled<F12>
#DEFAULT OPTION

# Adding Storage (NFS)
# Adding Storage (SMB)

log "Settings Storage options for the new vm migrated"
# log "Modifying Virtual machine"
$VBOXMANAGE modifyvm $PARAM_VM_NAME --nic1 nat --nictype1 Am79C973 #--vrdpmulticon on # --vrdp on

# log "Creating Sata driver in virtual machine"
# TODO: perguntar tipo de disco
$VBOXMANAGE storagectl $PARAM_VM_NAME --name "SATA Controller" --add sata --sataportcount 1

#log "Attach virtual harddrive"
# TODO: perguntar o uuid do disco e adicionar
$VBOXMANAGE storageattach $PARAM_VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $PARAM_VM_HD


log "Starting Migrate $PARAM_VM_SOURCE_HOSTNAME: from $PARAM_PM_SOURCE_HOSTNAME to $PARAM_PM_TARGET_HOSTNAME"
# Migrate
$VBOXMANAGE modifyvm $PARAM_VM_NAME --teleporter on --teleporterport 6000

log "Starting virtual machine in a remote phisical machine"
$VBOXMANAGE startvm $PARAM_VM_NAME &
log "wait 3"
sleep 3

log "[Init teleporting]" 
log "Send Virtual Machine"
$VBOXMANAGE controlvm $PARAM_VM_SOURCE_HOSTNAME teleport --host localhost --port 6000
#ubuntu-karmic teleport --host localhost --port 6000
sleep 10
#FIN

log "Set the option teleporter off"
$VBOXMANAGE controlvm $PARAM_VM_NAME poweroff
sleep 10
$VBOXMANAGE modifyvm $PARAM_VM_NAME --teleporter off

#Unregister and delete the new vm

$VBOXMANAGE storagectl $PARAM_VM_NAME --name "SATA Controller" --remove
$VBOXMANAGE unregistervm $PARAM_VM_NAME --delete

#. migrate.sh
#FIN2
