---
title: Folding@Redgate
layout: post
date: 2020-04-02
author: Nick Howell
feature-img: "assets/images/2020/03/coronavirus.jpg"
thumbnail: "assets/images/2020/03/coronavirus.jpg"
excerpt_separator: <!--more-->
---

It's fair to say that coronavirus has had a huge impact on our day-to-day lives. Many organisations have really stepped up and are putting huge amounts of effort into helping the world deal with it. 

One small thing I saw several references to, though, was the [Folding@Home](https://foldingathome.org/) project. It's something I had contributed to before, but had largely forgotten was a thing. It's main purpose is to simulate protein folding with the goal of using that information to allow medical researchers to develop vaccines and other treatments for various illnesses. 
<!--more-->

Unsurprisingly, they started providing work units for [Covid-19 research](https://foldingathome.org/covid19/) and calling on people to donate computing power. 

That gave me an idea. At Redgate we have a lot of spare computing capacity in our hypervisor clusters, so I figured it was worth spinning up a few VMs to run the folding client. While this isn't going to make a huge impact right away, hopefully it'll go someway to helping the longer term cause of finding a vaccine.

As many of our systems as possible are built and configured using Puppet, so I took the opportunity to write a [puppet module](https://github.com/njhowell/puppet-foldingathome) to install and configure the client.

The puppet module is fairly simple. It only works on Debian based systems for the moment though. 

As of today, Redgate now has 5x 8Core VMs running, each with 2x 4CPU work slots on them. We're also considering installing the client on our TeamCity agents to utilise the spare compute capacity there, although we obviously need to be careful not to disrupt our production workloads ;)

If you want to see how we're getting on, you can checkout our team stats page [here](https://stats.foldingathome.org/team/253928).

![](/assets/images/2020/03/fah_stats.jpg)

