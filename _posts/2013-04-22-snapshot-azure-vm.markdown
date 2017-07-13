---
layout: post
title: Snapshot and Restore Azure VM with PowerShell
date: 2013-04-22
author: Nick Howell
---
### Problem

You have a VM in Azure. You want to take a snapshot of it, so you can revert back to it at a later date.

Unfortunately, Azure doesn't currently support this, although it does support snapshots of a blob, which gives us a possible option.

### Solution

Following on from work [here](http://yossidahan.wordpress.com/2013/01/18/backing-up-a-windows-azure-virtual-machine-using-powershell/) which uses the [Cerebrata Azure Management cmdlets](http://www.cerebrata.com/products/azure-management-cmdlets/introduction). I've updated the steps to work with Azure *now* (April 2013). It seems that Microsoft changed something in Azure that means the method presented in that link no longer works (more on that in a minute) and probably means that my method will cease to work at some point in the future too.

There are two main sections to this:

* Taking the Snapshot of your VM
* Restoring the Snapshot

You'll need a couple things before this will work:

* Azure Powershell cmdlets
* The various bits of account information for Azure, as noted in the Azure cmdlets getting started guide here
* Cerebrata Azure Management cmdlets
* The name of your VM ($vmname)
* The service name your VM belongs to ($servicename)
* The storage account name ($storageaccountname)
* The storage access key ($storageaccesskey)
* The storage container name where the vhd resides ($containerName)
* The Azure location of your VM ($location)
* The URL of the blob representing the VD ($bloburl)

##### Snapshotting the VM

This is a relatively straightforward affair, but it would be a good idea to shut the VM down first. Remember, that the snapshot operation is performed on the blob storage object, so you'll take a snapshot of whatever is persisted to disk. If you take the snapshot while the VM is running you won't get the running state, so when you restore and start your VM it'll come up in a crash-consistent state.

`Stop-AzureVM -ServiceName $servicename -Name $vmname`

Once the VM has stopped, you can use the Cerebrata cmdlet to take the snapshot.

`$snapshoturl = Checkpoint-blob -BlobUrl $bloburl -AccountName $storageaccountname -AccountKey $storageaccesskey`

Note that the Checkpoint-blob cmdlet returns the URL of the newly taken snapshot. You should keep this because we'll need it later. I've stored it in a variable, `$snapshoturl`.

With all that done, you can start the VM again.

`Start-AzureVM -ServiceName $servicename -Name $vmname`

##### Restoring the VM

The process of restoring the snapshot is somewhat more involved than actually taking the snapshot.

When a disk is attached to a VM a lease is created which prevents access to that blob by everything else. This is also where my steps differ from the ones here. In order to perform the restore you must remove the entire VM and, as I've discovered, you also need to remove the disk (which is a separate entity to the blob) before you can perform the restore.

To start with, you'll want to stop the VM

`Stop-AzureVM -ServiceName $servicename -Name $vmname`

Then, export the VM config somewhere safe

`Export-AzureVM -ServiceName $servicename -Name $vmname -Path $configpath`

Where `$configpath` is some file path local to the machine where the script is running (e.g `c:\temp\myvmconfig.xml`).

Next, get and store the name of the disk that is attached to the VM (this assumes only one disk, so you may need to modify this if your VM has more than one).

`$diskName = get-azureDisk | where {$_.AttachedTo.RoleName -eq $vmname} | select DiskName`

Then you can remove the VM. If you remove the VM first, you'll then have difficulty getting the name of the disk.

`Remove-AzureVM -ServiceName $servicename -name $vmname`

Next, we need to wait for Azure to stop associating the disk with the VM. I've written a simple loop that does the waiting, you might want to tweak it to suit your needs, but this works well enough for me

`$attached = get-azuredisk | where {$_.DiskName -eq $diskname.DiskName} | select AttachedTo`
 
    while($attached.AttachedTo -ne $null)
    {
        start-sleep -s 20
        $attached = get-azuredisk | where {$_.DiskName -eq $diskname.DiskName} | select AttachedTo
    }
    
It takes a while for the association to go away (in my experience), hence the 20 second sleep between checks.

Once this completes, you can remove the disk

`remove-azuredisk -diskname $diskname.DiskName`

Then, you need to remove the service which releases the service name and then allows you to deploy the VM again.

`Remove-AzureService -ServiceName $servicename -force`

Finally, we can perform the restore of the snapshot

`$newblob = Copy-Blob -BlobUrl $snapshoturl -TargetBlobContainerName $containerName -AccountName $storageaccountname -AccountKey $storageaccesskey ` 

Again, this cmdlet returns the URL to the 'new' blob. Keep this, we'll need it in a second when we add a new disk

`Add-AzureDisk -DiskName $diskname.DiskName -MediaLocation $newblob.BlobUrl -OS 'Windows'`

This creates a new disk in Azure which references the newly restored vhd. Change the OS to whatever OS you have, but make sure it's an Azure recognised OS.

Finally, import the VM config we exported earlier and create a new VM

`import-azurevm -path $configpath | New-AzureVM -ServiceName $servicename -Location $location`

And that's it. You'll need to wait a while for the VM to boot, and if you put all this together in a script, then the whole process can take quite some time (10 - 15minutes in my experience!).
