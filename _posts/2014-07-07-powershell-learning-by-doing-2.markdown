---
layout: post
title: 'Powershell: Learning by doing #2'
date: 2014-07-07
author: Nick Howell
disqus_id: 6
---
#### Who needs psexec? We've got powershell...   

Todays gem is remote powershell. Specifically using invoke-command to execute the same code on multiple servers. 

I recently had a need to do just that -- I had to disable a schedule task on 7 servers and instead of RDPing to each of them individually, I opted to use powershell:

`invoke-command -ComputerName server1, server2, server3, server4, server5, server6, server7 -ScriptBlock {Get-ScheduledTask -TaskName detach* | Disable-ScheduledTask}`

This command executes the code inside the `-ScriptBlock {}` on each server in the list, server1-7 (not their real names) in this case.
