---
title: Automating Ubuntu 20.04 images with Packer
layout: post
date: 2020-05-01
author: Nick Howell
feature-img: "assets/images/2020/05/ubuntu-background.jpg"
thumbnail: "assets/images/2020/05/ubuntu-background.jpg"
excerpt_separator: <!--more-->
tags: [ubuntu,openstack,packer]
---
[Ubuntu 20.04](https://ubuntu.com/blog/ubuntu-20-04-lts-arrives){:target="_blank"} was released last week, so I set about creating a new image for our internal virtualisation platform. This post is about how we use [Packer](https://www.packer.io/){:target="_blank"} to automate the creation of images and what we had to do to get it to build Ubuntu 20.04.
<!--more-->

Packer is a tool from Hashicorp that automates the building of machine images. Natively it supports a huge range of virtualisation options, but for our purpose we use Virtualbox and VMWare Workstation. Our Virtualbox images are used by developers using Vagrant on their local systems, and our VMWare images are used for both Vagrant and our internal Openstack platform (which we use VMWare vCenter / ESXi for the compute resources).

The Packer [Getting Started](https://www.packer.io/intro/getting-started/){:target="_blank"} guide gives a good overview of how to use it. In a nutshell, a Packer configuration consists of an array of `builders` and, optionally, an array of `provisioners`. `Builders` define how to launch a VM on a particular platform, while the `provisioners` define what scripts to run on that image to prepare it in the way you want. Once those scripts have been run, Packer will shutdown the VM and export it in some way depending on the builder. For example, that may be an AMI for EC2, or a file such as a vmdk for VMWare images. You can have multiple `builders` in a single Packer configuration, which means you can effectively build an identical image for multiple platforms very easily.


### Building Ubuntu 20.04
I'm going to talk about a few of the things we do to provision our images, but it's worth noting that there are the [chef-maintaned bento boxes](https://github.com/chef/bento/tree/master/packer_templates){:target="_blank"} you can look at for full examples.

To build our Ubuntu 20.04 image, we start from scratch using the ISO. While it is possible to start from another image, we prefer this method because it gives us total control over what goes in the image.

You can see a full example of the Packer file we use [here](https://gist.github.com/njhowell/ce216470d6ed050e5b609244402aa00e#file-ubuntu-2004-json){:target="_blank"}. The most interesting part of this step is configuring the `boot_command`. This is a command that is typed at the install prompt when the ISO boots. Ours looks like this:
{% raw %}
```json
"boot_command": [
    " <wait><enter><wait>",
    "<f6><esc>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs>",
    "/casper/vmlinuz ",
    "initrd=/casper/initrd ",
    "autoinstall ",
    "ds=nocloud-net;s=http://{{.HTTPIP}}:{{.HTTPPort}}/ubuntu-20.04/ ",
    "<enter>"
    ],
```
{% endraw %}

There are a few interesting points to notice here. The first two lines get us from the splash screen to the custom boot command entry on the installer. Then, the large number of `<bs>` are shortcode for `backspace` -- we're deleting all the prefilled boot commands so we can type our own. 

Note that even though each of these entries is a new item in the array in our config file, they all get entered as a single line. It's just broken up like this to make it easier to read. 

We're using the new [AutoInstall](https://wiki.ubuntu.com/FoundationsTeam/AutomatedServerInstalls){:target="_blank"} method for Ubuntu 20.04. Previous versions use debian-installer preseeding, but that method didn't immediately work with the new ISO. 

Packer will start a small HTTP server when the build is run and substitude the {% raw %} `{{.HTTPIP}}` and `{{.HTTPPort}}` {% endraw %}variables with the corresponding IP and Port. You must also set the `http_directory` configuration option to specify which directory on your filesystem hosts the files you want the HTTP server to serve. We have a directory called `ubuntu-20.04` within that directory, and that in turn contains a `user-data` file which contains our AutoInstall config. I also found that AutoInstall expects a file called `meta-data` to be present, although it doesn't require any content so I simply have an empty file called `meta-data` alongside `user-data`.

Our `user-data` file looks like this

```yaml
#cloud-config
autoinstall:
  version: 1
  apt:
    geoip: true
    preserve_sources_list: false
    primary:
    - arches: [amd64, i386]
      uri: http://gb.archive.ubuntu.com/ubuntu
    - arches: [default]
      uri: http://ports.ubuntu.com/ubuntu-ports
  identity:
    hostname: ubuntu2004
    username: vagrant
    password: <encrypted password>
  ssh:
    allow-pw: true
    install-server: true
  locale: en_US
  keyboard: 
    layout: gb
  storage:
    layout:
      name: direct
    config:
      - type: disk
        id: disk0
        match:
          size: largest
      - type: partition
        id: boot-partition
        device: disk0
        size: 500M
      - type: partition
        id: root-partition
        device: disk0
        size: -1
  late-commands:
    - "echo 'Defaults:vagrant !requiretty' > /target/etc/sudoers.d/vagrant"
    - "echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /target/etc/sudoers.d/vagrant"
    - "chmod 440 /target/etc/sudoers.d/vagrant"
```

Note that the vagrant bits are somewhat unique to us. We create a user called `vagrant` as part of the install. That's so we can use this image as a vagrant box later on. Note also at the end that we add `vagrant` to the sudo config and ensure that it doesn't require a password to run sudo commands. This ensures that when the image is used in vagrant, it doesn't prompt for a password before running a command with root privileges. 

Then we come to the provisioners. For this base image we run two scripts, one to update all the packages, and the other cleans up a few things:

```bash
sudo apt-get update
sudo apt upgrade -y
sudo apt install apt-transport-https -y
```

and 

```bash
sudo apt-get clean
FILE=/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi

FILE=/etc/cloud/cloud.cfg.d/curtin-preserve-sources.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi

FILE=/etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
if test -f "$FILE"; then
  sudo rm $FILE
fi
```

The interesting thing in the second script is the removal of the `*.cfg` files from `/etc/cloud/cloud.cfg.d/`. Those files get created by AutoInstall and include config that prevents cloud-init from correctly running a second time. Probably not a problem in most cases, but our VMDK images are destined for Openstack which uses cloud-init to configure the instances on boot.


Finally, we repeat this style of config many times for different versions of Ubuntu and CentOS, but also for Windows desktop and Windows Server editions. In most cases we build a base image from an ISO, as above, and then build more specialised images using those base images as starting points. Some of our more complicated configurations also use [Puppet as a provisioner](https://www.packer.io/docs/provisioners/puppet-masterless/){:target="_blank"} to install things such as SQL Server, Oracle or Visual Studio to allow our development teams to easily test against those platforms.
