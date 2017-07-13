---
layout: post
title: Puppet test environment with Vagrant
date: 2015-08-08
author: Nick Howell
---
I wrote a post a little while ago about my [Puppet development workflow](https://nickhowell.co.uk/2015/02/20/puppet-development-workflow/) where I talked about using source control for your manifests and a CI server (Jenkins in that case) to automatically check your code and deploy it to your puppet master. 

Since then, I've done some more work with Puppet and found that working on manifests locally, committing to source control, waiting for the build to complete and the code to deploy to the puppet master takes far too long when you're not really sure if what you're doing is going to work. 

So. Is there a better way? Well... I think there is and it means using [Vagrant](https://www.vagrantup.com/). If you haven't used Vagrant before, go and check it out. It's a great little tool that allows you to automate the creation of Virtual Machines on your local system and perform a set of pre-scripted steps on said virtual machine to configure it and get it into a known state ready for you to do some development on. That's fairly simplistic way to look at it and as you read through the [Vagrant getting started guide](http://docs.vagrantup.com/v2/getting-started/index.html) you'll soon realise it can do so much more.

Back to puppet then. How does this help? Well with some careful scripting it means we can take a blank Linux image (Ubuntu in my case) and turn it into a fully functional puppet master that uses your locally checked-out copy of the puppet manifests. You can then spin up test puppet clients and have them contact your puppet master running in vagrant to check your code works. If it doesn't, you make the change, save the file and re-run the puppet agent. Keep doing that until it all works the way you want and then commit to your source control and let your CI server do the rest to get it live. 


#### Setting it all up
There are a few parts to work out here to do with Vagrant so if you haven't used it before, I'd suggest you read at least some of the getting start guide first. 

My workstation is a Windows machine, so I'm using [VirtualBox](https://www.virtualbox.org/) to provide my VMs for Vagrant.

To provision the VM using Vagrant I have 4 different files:

* The **Vagrantfile**
* A shell script to get puppet installed called **provision_puppetmaster**
* A puppet manifest that gets applied by the shell script above called **default**
* And a pre-configured config file for the puppet server called **puppetserver**

You can find all of these files in [this github gist](https://gist.github.com/njhowell/0dc3a1f8c680ea0b969c). I won't claim that they are perfect as there are undoubtedly improvements that can be made, but they work for me. 


###### Vagrantfile
First up, the Vagrantfile. This is fairly standard to be honest. The important part is to ensure you connect it to a public network (not a NAT'd one) if you want any other machines on your network to access the puppet master. Also make sure you give it a hostname -- I call it puppet, but you might want to call it something else like puppettest to avoid collisions with your live production system.

You also want to configure a synced folder. In my case my Vagrantfile is stored in a sub-directory of my puppet repo, so I sync the parent directory ("../") with "/etc/puppetlabs/code/environments/production" in the puppetmaster which is where puppet expects to find the manifests for the production environment by default. This is the part that allows you work in real time on your manifests on your development machine and have them immediately available in your test puppet master for testing on your test clients.

###### provision_puppetmaster
This is a set of scripted steps to turn a blank Ubuntu machine into a Puppet master.

It first adds the puppet apt repository, before removing any currently installed version of puppet and deleting it's ssl store. 

We then install the latest puppet-agent from the puppetlabs repository, and use puppet itself to configure this VM as a puppet master. The **default.pp** manifest that we apply simply ensures that the puppetserver, ruby-dev and r10k packages are installed. 

To finish up, we copy a predefined **puppetserver** config, start the puppetserver service and then change to the manifests directory and use r10k to install all the modules in the puppetfile. That step is entirely optional, and depends very much on whether you use r10k at all.


#### Conclusions
This is just one of many ways to develop with Puppet -- I'm sure you can tell me of many more, and make strong arguments for and against this method, and any other method you care to think of. 

For me, it works. It gives me the option to experiment and use trial and error to get my manifests to do what I want without polluting the VCS history or introducing breaking changes to other people working on it at the same time. Of course, you still need to have some discipline to make sure you work in small chunks and commit regularly when it works, otherwise you lose the point of having source control in the first place.

It's also nice to know that if the worst should happen to your live Puppet master, you have a script that can turn a blank machine into a fully functioning Puppet master in about 5 minutes. On top of that, you know that your testing environment is the same as live which is definitely a Good Thing.

