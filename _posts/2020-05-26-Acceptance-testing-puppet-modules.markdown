---
title: Acceptance testing Puppet modules with PDK, Litmus and Vagrant
layout: post
date: 2020-05-26
author: Nick Howell
feature-img: "assets/images/2020/05/puppet.jpg"
thumbnail: "assets/images/2020/05/puppet.jpg"
excerpt_separator: <!--more-->
tags: [puppet,pdk,litmus,vagrant]
---
Not long ago Puppet released the [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/1.x/pdk.html){:target="_blank"} which was designed to simplify the process of creating Puppet modules to a consistent standard. Until I wrote the [folding@home]({% link _projects/folding_at_home_puppet.md %}){:target="_blank"} module, I had never written a module for the forge and I was a little concerned I wouldn't get the coding standards correct. This post is a summary of how I used PDK, as well a Litmus and Vagrant to write and test a module.
<!--more-->

PDK can be used to create a barebones module which sets up the correct directory structure, and templates some unit tests for you.

You get the commands `pdk validate` to perform basic parsing of all the relevant files, and `pdk test unit` to run your unit tests.

Puppet have some excellent documentation available [here](https://puppet.com/docs/pdk/1.x/pdk.html){:target="_blank"} that includes how to install PDK, how to create a module using it and how to test, so I won't go over that. 

However, documentation on using Litmus for acceptance testing, and in particular using it on Windows where you don't have docker to hand isn't as forthcoming so this is my attempt to fill in a few of the blanks that I had. 

## Getting started

[njhowell/puppet-pdk-example](https://github.com/njhowell/puppet-pdk-example){:target="_blank"} contains an example puppet module created using PDK. I've created a default class that just creates a temp file for the purposes of this. 

Running `pdk validate` will parse the various files in the module, and `pdk test unit` will run the unit tests. The automatically generated unit test simply checks that the module compiles.


## Acceptance tests
PDK includes `puppet_litmus` in the `Rakefile` that it generates, but there's still a bit more config to do to get started. 

Full details are on the [Litmus wiki](https://github.com/puppetlabs/puppet_litmus/wiki/Converting-modules-to-use-Litmus){:target="_blank"} but if you've started with PDK, then you need to do the following:

1. Add some extra code to your `.fixtures.yml` file
   ```yaml
   ---
    fixtures:
        repositories:
        facts: 'https://github.com/puppetlabs/puppetlabs-facts.git'
        puppet_agent: 'https://github.com/puppetlabs/puppetlabs-puppet_agent.git'
        provision: 'https://github.com/puppetlabs/provision.git'
    ```
2. Add or update code in `spec/spec_helper_acceptance.rb`
    ```ruby
    # frozen_string_literal: true

    require 'puppet_litmus'
    require 'spec_helper_acceptance_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_acceptance_local.rb'))
    include PuppetLitmus

    PuppetLitmus.configure!
    ```


Next up, I created `provision.yaml` in the root of my module to create a provision list for litmus to use. This effectively lets you define lists of VMs to start to run your acceptance tests against.

For this example, I create a list called 'vagrant' and have it create a Ubuntu 18.04, Ubuntu 20.04 and Debian 9 VM using the virtualbox provider.

```yaml
---
  vagrant:
    provisioner: vagrant
    images: ['generic/ubuntu1804', 'generic/ubuntu2004', 'generic/debian9']
    params:
      vagrant_provider: virtualbox
```

You can replace the image names with any image from [VagrantCloud](https://vagrantcloud.com){:target="_blank"}. Just make sure the image supports the provider you're using (virtualbox in this case).

Next, lets see if it works. 

Run `pdk bundle install` to install the gems listed in your `Gemfile` (this should be auto generated, so no need to modify it).

Then, you can start your VMs. Run `pdk bundle exec rake litmus:provision_list[vagrant]`. After a short while, you should see it using the vagrant provisioner to create your VMs.

We're only part way there though. We still need to install the puppet agent, fix up the PATH environment variable (special step needed for vagrant images), install our module, run the acceptance tests, and then we can destroy the VMs. Before we get to any of that though, we should write some acceptance tests. 

In the `spec` folder, create another subfolder called `acceptance` and inside that create a file named for your class. For example, in this case it'll be `example_spec.rb`. A very simple acceptance test might look like this:
```ruby
require 'spec_helper_acceptance'

pp_basic = <<-PUPPETCODE
  class {'example':

  }
PUPPETCODE

idempotent_apply(pp_basic)
```

Use the `pp_basic` variable to write some puppet to apply your module in some way. This class is very simple, but a more complex one may include parameter values for example.

This is also a very simple test - all is does is check that the manifest is applied in an idempotent way. You'll want to add more tests to confirm that it's actually creating the resources you expect.

With that done, we can put it all together:

- `pdk bundle exec rake litmus:install_agent` will install the puppet agent on each VM you provisioned
- `pdk bundle exec bolt task run provision::fix_secure_path --modulepath spec/fixtures/modules -i inventory.yaml -t ssh_nodes` This calls a bolt task directly and references the inventory.yaml file that litmus generates in the provision stage.
- `pdk bundle exec rake litmus:install_module` installs the module we're testing
- `pdk bundle exec rake litmus:acceptance:parallel` runs our acceptance tests.


If all went to plan you should see that the tests finished with no failures. At this point you can either tear down the VMs, or make changes to your module, install it again, and run your tests some more.

Tear down the VMs with `pdk bundle exec rake litmus:tear_down`.


## Summary

Litmus offers a nice framework for running acceptance tests, and it seems to be where the Puppet community is moving. Most examples use docker, which is great if you're developing on Linux, or have docker on windows configured. Unfortunately, I used VMware Workstation and Virtualbox, which prevents me from also having Hyper-V (and thus docker) running on my system.

