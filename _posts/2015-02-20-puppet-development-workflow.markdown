---
layout: post
title: Puppet development workflow
date: 2015-02-20
author: Nick Howell
disqus_id: 7
---
I've been working with [puppet](http://puppetlabs.com) at [Red Gate](http://www.red-gate.com/) for a while now. Up until recently our code base has been fairly small -- it was more of a trial than anything, but it has slowly proven itself and now nearly all new services are provisioned using puppet if it makes sense to. 

As a result our code base has grown and we're starting to see the pain of our (lack of) development workflow.  I also use puppet at home to configure the server this blog runs on, as well a few little servers I have in my house. So, I thought I'd see if there was a better way to develop puppet manifests using my home environment as a test bed, and that's what I intend to share here.

Here are a few high level points, I'll dive into more detail for a few of them further down:

* **Use source control** Most things are git these days, so I have a *single* repo on [bitbucket](http://bitbucket.org) to store my puppet manifests.
* **Use puppet environments** More on why in a minute, but suffice is to say it opens up a few opportunites for development.
* **Embrace some, or part of, the roles and profiles design pattern** [This](https://docs.puppetlabs.com/pe/latest/puppet_assign_configurations.html#assigning-configuration-data-with-role-and-profile-modules) is a way of designing your modules and classifcations so they don't get too cumbersome.
* **Get a CI tool of some kind** More on this in a minute, but combine it with source control and puppet environments and you have the makings of a nice automated workflow.



#### Using a CI tool with puppet
I chose to use Jenkins (because it was free, and relativly easy to set up) but you could use just about anything. For the rest of this though, there will be a few Jenkins specific things.

First up, the git repo. Mine contains two folders:

* manifests
* modules

The structure beneath these matches what puppet expects. 


Next up, you need some plugins for Jenkins:

* [git](http://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin)
* [bitbucket](https://wiki.jenkins-ci.org/display/JENKINS/BitBucket+Plugin)
* [publish over ssh](http://wiki.jenkins-ci.org/display/JENKINS/Publish+Over+SSH+Plugin)

You'll need to configure a destination for the Publish Over SSH plugin. This is the server and directory where you want to publish your puppet files to. In my case, that's `/etc/puppet`. 

Next up, I have a single project in Jenkins that is set to get source code from my git repo. Enter the repo url, and specify the required credentials (I created a deploykey specifically for this).

Choose to build all branches, and trigger the build when the change is pushed to BitBucket. Remember to set a POST hook on your git repo to point to `http://<jenkins_URL>/bitbucket-hook/`.

For the build steps, I'm opting to perform some syntax checking using the builtin `puppet parser validate` command. Obviosuly in order for this to work you'll need puppet installed on the jenkins server. For the build step itself I'm checking every .pp file in the repo

    for file in $(find . -iname '*.pp')
	do
      puppet parser validate --render-as s --modulepath=modules "$file" || exit 1;
    done
    
`puppet parser validate` simply checks syntax of your individual .pp files. If an error is found, the build is failed.

Next, the post build actions. This is where the puppet manifests/modules get deployed to the puppetmaster over ssh after a sucessful build. This is also the point where puppets environments come in useful. 

Add the 'send artifacts over SSH' action and choose the destination server you configured for the plugin earlier. 
In the first transfer set leave all fields blank except 'exec command'. Here, I entered:

    cd /etc/puppet/environments/
    mkdir -p ${GIT_BRANCH}
    rm -rf ${GIT_BRANCH}/*
    
this very crude sequence of commands will create a folder in the environments folder matching the name of the git branch we just built if one doesn't exist. It then removes all existing files from that folder if it did exist (this ensures that after each build we only have the manifests we want).

Add another transfer set and set Source Files to `**` (this means copy all files) and set the remote directory to `environments/${GIT_BRANCH}/`. This path is relative to the one defined in the plugin config (`/etc/puppet/` in my case). 

And that's it. Save the config, and run a build. It should take your repo, check all your .pp files for syntax errors and then put them into an environment folder named after the branch. A brief note on that -- ${GIT_BRANCH} actaully contains the name of the remote repository (defaults to origin), followed by name of the branch currently being used, e.g. "origin/master" or "origin/foo". As a result, I set my puppet environment path to `/etc/puppet/environments/origin/` in the main `puppet.conf` file to get the behaviour I wanted.


##### Why bother?
Well, good question. There are two really useful bits to this, as far as I can tell.

* Automatic deployment of your changes to the puppetmaster as soon as your push the changes to your repo. This is massively helpful as it makes it so much easier to develop manifests on a workstation and then be able to test them in a real environment shortly thereafter. It also forces you to make changes and commit them to version control instead of sneakily editing them directly on the puppetmaster.
* By deploying your git branches to puppet environments of the same name you can easily branch your puppet code to develop a new module or configuration and test it out in isolation on test nodes that are looking for that specific environment. Once you're happy it works, you can merge that branch back to your 'production' branch to make the changes live in your production environment. 

##### What next?
There are plenty more things that can be added to this workflow. You could make use of puppet-lint, for example, to check the style of the manifests. You could even take it a step further and do some full-on automated testing of your puppet code if you wanted.

For me, I'm going to take some of this knowledge and work with a few of my colleagues to see how we can implement this at Red Gate (and, indeed, if we should). 



###### References
* Puppet Environments - https://docs.puppetlabs.com/puppet/latest/reference/environments.html
* Jenkins Puppet module - https://forge.puppetlabs.com/rtyler/jenkins
* Puppet environments workflow with Git - http://puppetlabs.com/blog/git-workflow-and-puppet-environments
* Git to puppet deployment workflow - https://sysadmincasts.com/episodes/33-git-to-puppet-deployment-workflow
