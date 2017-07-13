---
layout: post
title: My Home Network Has Got a Little Out of Hand
date: 2016-07-16
author: Nick Howell
---
I was sat my computer the other night and something occurred to me. _My home network has got a little out of hand_.

I don't mean that in the sense that is it untidy, or that there are cables trailing all around the house. Instead, just the sheer number of devices I have connected and _doing things_.

So, I decided to write it down to see exactly _how_ out of hand it really was. Plus...I'm a sysadmin and documenting your stuff is good practice, right? 

Here we go then. This is what I have in my network:

- 1 Router
- 1 8 port Gigabit switch
- 1 NAS
- 3 Raspberry Pi's
- 1 Mini ITX PC
- 2 Games Consoles
- 1 ESXi Server
- 5 VMs
- 2 Desktop PCs
- 2 Laptops
- 2 Rokus
- 2 Android Tablets
- 2 Smart Phones
- 1 Printer
- 2 SONOS Play:1 Speakers


![](/assets/images/2016/07/2016-07-16-15-25-03.jpg)
The router is a standard unit supplied by my ISP. It gives me WiFi and NAT. A single connection is made from that to the switch which handles all other switching. 
DNS and DHCP are handled by the Mini ITX PC which runs dhcpd and BIND on Ubuntu.

The NAS is a [Western Digital My Cloud](http://www.wdc.com/en/products/products.aspx?id=1140) which, to be honest, is a bit crap. I've had to enable SSH and disable most of the _"value add"_ features they put on just to get a vaguely usable SMB share.

The Raspberry Pis each perform a different role; 1 acts as a Print Server, 1 has an XRF module from [the wireless inventors kit](http://openmicros.org/index.php/articles/81-xrf-projects/296-raspberry-pi-wireless-inventors-kit) and acts as a sensor gateway for a light and temperature sensor in my living room. The third Pi sits up in the attic with my model railway where it controls a point motor via some relays. Eventually when I get back to it I'll add more point motors and relays and control the entire layout.

Next, the VMs. There's a few of these. One of them runs [EmonCMS](https://emoncms.org/) which stores and present the sensor data collected by the Pi above. There's also a [Plex](https://www.plex.tv/) Media Server and a [puppet](https://puppet.com/) master. Finally, there's a VM for running [docker](https://www.docker.com/) containers. Those are for a little project I have on the go for digitising VHS tapes. The tapes get recorded using a TV Capture card in one of the PCs to mpg. That file is stored temporarily by another VM and added to a RabbitMQ queue. Container instances then take a file from the queue and begin transcoding it to mp4 for long term storage. 

The remaining items are fairly straight forward; An Xbox One, Wii and Roku 2 make up the TV unit in the living room. While a Roku Streaming stick and one of the SONOS Play:1's live in the bedroom. The other SONOS is in the kitchen.

If you'll excuse the terrible diagram and handwriting, this is what it looks like if you draw it out.
![](/assets/images/2016/07/network.png)

All in all, that's not a small number of devices for two people... and yet, I would happily add more. In most cases I don't add these things because I _need_ to. I do it because I enjoy it. I'm a sysadmin by day and I enjoy tinkering in my spare time. Yes, my home network is a little out of hand....but y'know what? On balance, I think I like it that way. 

