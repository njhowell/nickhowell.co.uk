---
layout: post
title: Hyper-V VM loses network connectivity
date: 2016-07-12
author: Nick Howell
disqus_id: 13
---
I have an interesting problem at the moment where a selection of our VMs will stop passing network traffic. It doesn't seem to be a flat out disconnect, rather it behaves more like the virtual switch is just *dropping packets* instead of forwarding them on like a good switch should.

So, what actually happens? I have two Hyper-V clusters, each running on Windows Server 2012 R2. One is a 5 node cluster, the other only has 2 nodes. Every now and then (usually once or twice a week) a VM will suddenly drop off the network. We'll take a look to find the VM up and running but showing that the network has no Internet access -- the little yellow triangle of doom.

Further investigation at this point reveals that:

* You cannot ping any other IP from the VM. Including the host and other VMs on the same virtual switch.
* Traceroute is similarly unhelpful and confirms that you can't get out of the VM.
* Pings and traces going the other way also fail.
* Using Wireshark on the VM shows only ARP requests leaving the VM, but using Wireshark on the host at the same time you see no such requests.
* Using Wireshark you see no packets coming back into the VM.


I have been speaking to Microsoft to try to resolve this issue with no luck so far. We did attempt to start a `netsh trace` on both VM and host, which was unsuccessful. The `netsh` command just hangs in the VM and never completes. 

This happens to VMs on both clusters and is not confined to a single host. My initial speculation was that it was an issue with the virtual switch and installing a recent batch of Windows Updates was to blame. However, rolling those back had no effect. 

Microsoft's initial thought was that it was something on the VM that was at fault. I wasn't sure that could be the case given it happened on multiple VMs, seemingly at random, but some more recent developments (such as the issue running `netsh`) are making me reconsider. 

Right now Microsoft think it could be a filter driver in the VM, in particular the one from our ESET AntiVirus software. It's certainly plausible, so we have removed it for now and we'll see what happens over the next week.

I'll post updates here with how we get on...


**2016-07-23 Update**: It's been a little over a week now, and since removing ESET AV from the server we have had no more network failures on that particular VM. I'm keeping an eye on it, but I suspect this will prove to be the culprit. 
