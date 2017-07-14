---
layout: post
title: Unable to edit boot images after upgrade to SCCM R2 SP1
date: 2015-12-07
author: Nick Howell
disqus_id: 10
---

After upgrading to SP1 for SCCM 2012 R2 I found I could no longer edit my boot images.

Turns out that during the upgrade I removed ADK8.1 and replaced it with ADK10 and you cannot edit older boot images with the newer ADK. Go figure.

In my case I chose to just create a brand new boot image from ADK10 and reimport all my drivers to it instead of faffing about with making the old image usable. Thankfully this is made much easier in SP1 by the addition of a filter to only show network and storage drivers which is all you should have in boot images anyway.

Here are the steps to create a new boot image.

1. Run *Deployment and Imaging Environment (Windows ADK)* as Administrator
2. Recreate the boot image via `COPYPE.CMD`:
    1. `COPYPE.CMD x86 c:\WINPE86`
    2. `COPYPE.CMD amd64 c:\WINPE64`
3. Copy boot.wim from `c:\WINPE86\media\sources\` into the SCCM DP Share. Repeat for the amd64 image.
4. Import the boot image into SCCM as normal
5. Add drivers
6. Distribute to DPs


With the new boot image(s) in place, you can update your task sequences to use it.

In general, SCCM uses the boot image that was used in the most recently advertised task sequence as the default boot image during a PXE boot.
