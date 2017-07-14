---
layout: post
title: Digitising VHS Tapes
date: 2017-01-18
author: Nick Howell
disqus_id: 17
---
As I'm sure many people do, we have a huge stack of old VHS tapes and a VHS player that I really don't want sat under my TV any more. On the other hand, I do have a Roku sitting there, and Plex Media Server set up on my LAN so I formed a cunning plan: I would digitise all our VHS tapes and store the resulting files in Plex so we could watch them on any TV in the house whenever we wanted.

Fortunately, I had an old PC in the loft that had a Hauppage WinTV card that took a composite video input. Unfortunately, the WinTV application was the only way I could record the video in Windows, and that only worked on Windows 7. I dug out an old Windows 7 installer and got to work. Shortly thereafter I had a working WinTV install, which is where I discovered my next problem. The only SCART -> Composite adapters I had were all video *in*, rather than video *out* and I couldn't find my switchable one. Thankfully the internet has pin outs for SCART connectors, and with the appropiate application of a soldering iron I soon had a frankendapter that would do both video *in* and *out*.

After about half a day of faffing around I had a system that could capture video. The only downside was that a 2 hour video produced a 5GB mpg file. That file needed transcoding to something more sensible like x264 in an mp4 container. This is where I got a bit carried away.

Instead of doing what any sane person would and just using Handbrake, I thought it'd be much better to create myself a little encoding server. Except it was more like an encoding farm...or at least has the capability of being such a thing.

At a high level, it consists of:

* A file share on my NAS
* A message bus (RabbitMQ on an Ubuntu VM)
* One or more encode servers running as Docker images.

The basic process flow is this:

1. The file to be encoded is put in a special directory in the file share
2. A script on the RabbitMQ box runs every 5 minutes to check for files. When it finds one it moves it to another directory and adds a message to the bus with the files pathname.
3. Inside the Docker instance(s) a script is continuously polling the message bus for new messages. When it gets one it takes it off the queue (but doesn't ack, yet) and begins encoding it using ffmpeg.
4. When the encode completes the file is put in another directory and the message from the queue is ack'd.


This is far more complicated than I required, but it was fun to do. There's a few nice features about this:

* If a Docker instance dies, then the message eventually times out and goes back on the queue to be consumed again.
* If there are a lot of files to encode, then you can start additional instances of the Docker image on other machines and encode multiple files in parallel.


However, there is also a few problems:

* If the encode fails, or the ffmpeg process dies, the message still gets ack'd. Some error checking would be nice but I can't really be bothered with that for this.
* There is not currently any way to change the encode parameters on a per video basis.
* It's not possible to specify an output file name or location.


If I took this much further I think I'd end up with a very small scale version of Amazons Elastic Transcoder, which on the face of it appears to work in a similar way.... perhaps that's where I got the idea from.

#### Did it work
So...how has the plan gone? Well....I've got one box full of VHS tapes that have been digitised, and about another 10 tapes to go, which is pretty good I think. The process actually works quite well, except for the part where I have to cue up and start/stop the recording of the tapes manually....unfortunately I don't think there's really a way around that.
