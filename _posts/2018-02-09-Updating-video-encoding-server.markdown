---
title: Updating my video encoding server
layout: post
date: 2018-02-09
author: Nick Howell
excerpt_separator: <!--more-->
---
A while back I started a process to convert VHS tapes to digital videos and part of that involved transcoding the mpg files that were captured to slightly more reasonable h264 mp4 files.
<!--more-->
Mostly because I wanted to learn, I completely over-engineered the solution and instead of just using Handbrake, I set about create an encoding farm involving a NAS, a RabbitMQ message bus, and a couple docker containers to actually do the encoding work.

This worked pretty well, but there were still a few flaws that I mentioned in [my post at the time]({{ site.baseurl }}{% post_url 2017-01-18-digitising-vhs-tapes %}).

This week, I had a bit of time to tackle this problems and see if I could improve the system. Turns out I could.

I stumbled across a python project called [Celery](http://www.celeryproject.org/) which promised to deal with the task queue element of the system. One of the problems I had was that if an ffmpeg process died while encoding, then the message would still get ack'd even though the process failed. Celery solves that by only ack'ing the message once the process completes *successfully*.

Another nice feature I noticed was that you can query the state of workers. Running `celery inspect active` in the working directory of the application on any of the worker nodes gives a list of the workers currently up and the message they're processing.

I made a couple other changes too. Instead of this being a docker application, I moved it to a simple python app that runs in a VM. Docker didn't make sense for this, and it was far simpler to just have an Ubuntu Server VM configured by puppet.

Puppet ensures all dependencies are installed, checks out the code and ensures the worker process is running using `Supervsiord`. Supervisor can then be used to stop the worker process if needed, and the nice thing about Celery is that if you do that before an encode completes, the message gets requeued and another worker will deal with it instead.

The whole project is in [Github here](https://github.com/njhowell/python-videoencoder). There are two main components:
 * `queueFiles.py` deals with getting the messages onto the queue. It doesn't really matter how this is done, only that it is.
 * `videoTasks.py` contains the `encode` function that actually does the processing. Here you'll find the `ffmpeg` command that gets executed. It's pretty basic, but I find it covers most scenarios with good quality output.
