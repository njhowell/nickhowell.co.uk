---
layout: post
title: "(Really) Rapid VM Provisioning with SCVMM 2012 R2"
date: 2015-03-28
author: Nick Howell
---
One of the biggest problems I've found with using Microsoft System Center Virtual Machine Manager (SCVMM) and Hyper-V is that deploying a VM from a template can take a really long time (15 minutes in my case).

It seems to depend on two factors in particular:

* The time it takes to copy the template, and;
* The time is takes OS Customisation to complete.

Of course, to speed up the first you can make use of ODX or SAN Copy, or you can just throw faster storage and networking at it. But what if you don't want to, or can't? 

Well, instead you can use differencing disks. This is a new feature to SCVMM 2012 R2 and when deploying a VM to a host you can choose to use differencing disk optimisation. 
![Differencing Disk](/assets/images/2015/03/diffdisk.png)
Doing this will deploy the template VHD once to storage accessible by the destination host and then create a differencing disk to store all modifications. Subsequent deployments of that same template will use the same parent disk that's already deployed and need only create a new differencing disk which is a very quick operation.

OK. So what about OS Customisation. Well, there isn't a lot we can do there that isn't already being done by SCVMM. But what about not doing it? That certainly is possible if it fits in with your use case.

The scenario I'm thinking of is one for automated testing. In this scenario we have a template we want to start up, perform some operations on and then discard. We don't care about machine name, machine ID, domain membership or any of the other stuff that Sysprep handles for us.

To make this happen, we first need to create the template. Get your VM set up how you want it, then choose to create a template of it. When you get to it, specify that no OS Customisation in required. This prevents Sysprep from running and simply copies the VHDX of your shutdown VM into the library. When you come to deploy it you'll get an exact copy of the VM you started with. 

If you deploy it using the differencing disk method, then after the first initial deployment I've seen subsequent deployments complete in as little as 16 seconds. Admittedly I think that was a fluke, but I've seen fairly consistent results around the 30 second mark.

Take this a step further and you can script the deployment of a VM using PowerShell and the SCVMM module. 
 
My script looks like this:

```

param(
    [string]$templatename,
    [string]$vmname,
    [string]$StorageClassificationName,
    [string]$cloudname
)
import-module virtualmachinemanager

$start = get-date
$jobid = [System.Guid]::NewGuid().ToString()

$Template = Get-SCVMTemplate -VMMServer vmmserverfqdn | where {$_.Name -eq $templatename}
$cloud = Get-SCCloud -Name $cloudname
$virtualMachineConfiguration = New-SCVMConfiguration -VMTemplate $Template -Name $vmname -Cloud $cloud
$VHDConfiguration = Get-SCVirtualHardDiskConfiguration -VMConfiguration $virtualMachineConfiguration

$StorageClassification = Get-SCStorageClassification -Name $StorageClassificationName
Set-SCVirtualHardDiskConfiguration -VHDConfiguration $VHDConfiguration -PinSourceLocation $false -PinDestinationLocation $false -FileName "$vmname - Diff"  -DeploymentOption "UseDifferencing" -StorageClassification $StorageClassification |Out-Null

Update-SCVMConfiguration -VMConfiguration $virtualMachineConfiguration | Out-Null

$vm = New-SCVirtualMachine -Name $vmname -SkipInstallVirtualizationGuestServices -StartVM -VMConfiguration $virtualMachineConfiguration -Cloud $cloud -Description "" -JobGroup $jobid -UseDiffDiskOptimization -StartAction "NeverAutoTurnOnVM" -StopAction "SaveVM"


start-sleep 20
get-scvirtualmachine $vm | Refresh-VM

$ips = get-scvirtualmachine $vm | Get-SCVirtualNetworkAdapter | select ipv4addresses

while(($ips.IPv4Addresses|measure-object).count -eq 0)
{
    start-sleep 10
    get-scvirtualmachine $vm | Refresh-VM
    $ips = get-scvirtualmachine $vm | Get-SCVirtualNetworkAdapter | select ipv4addresses
}

write-host $ips[0].IPv4Addresses


$end = get-date


write-host "Started at $start, complete at $end"
```

There are several steps involved, and obviously it's very specific to my need, but it can be easily adapted.

To start with, we take a bunch of parameters from the command line - template name, vmname, storage classification name, cloud name. These are all fairly self explanatory.
Next up, get the VMM module, a guid for the job and record the start time. The time is just for me  -- I like to see how long it's taken. 
Then, find the template, the cloud, the storage classification and get the configuration for the VM and VHD from the template. We need to modify the disk configuration at this point to specify that we want to use differencing disks, and the storage classification. You can also set the name of the differencing disk here. I've chosen to take the vm name and append " - Diff" to it. 

Then, update the VM configuration with those changes, and deploy our new VM. Store the result in a variable and then go to sleep for 20 seconds. That's a little bit of time to wait for the VM to boot, after that refresh the VM and inspect the VM object to see if it has an IP address. Your VM needs to use DHCP for this bit to work (you can't use a Static IP pool because you're not doing OS customisation). I keep refreshing the VM every 10 seconds to see if it has an IP address yet. As soon as it does write it out to the console and then write how long the whole process took. Obviously what you do at the end can be changed - my intention would be to return just the IP address so the calling process can use that to contact the VM it just started.

This whole process, from nothing to running VM that I can RDP to, takes about 1min 30 on my systems which is a significant improvement over 15 minutes without using Differencing Disks and using Sysprep.

This is my no means a fool-proof method for deploying VMs quickly. There are some compromises that need to be made, and some things that just aren't possible. One thing to watch out for is that if you deploy a VM using the differencing disk method and then create a template from it, you only store the differencing disk in the library. SCVMM will not flatten the disk chain, or store the other disks in the chain alongside it. That means you can very quickly get into a mess with different disks in the chain being stored in different places and it won't be obvious which disks are where.

All in all, if you're careful and use this method for a specific purpose then it could be very powerful and offer some huge time savings.
