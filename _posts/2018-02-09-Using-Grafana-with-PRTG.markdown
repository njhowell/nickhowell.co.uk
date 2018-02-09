---
title: Using Grafana with PRTG
layout: post
date: 2018-02-09
author: Nick Howell
---
I've been using [PRTG](https://www.paessler.com/prtg) at work for a long time now, and recently started using the free tier at home for my own projects.

It works really well, but one of the things I found quite lacking was it's ability to create dashboards. Sure, you have maps but there's only so much you can do there, and they just don't look all that good.

Then I found [this blog post](https://blog.paessler.com/prtg-plus-grafana-ftw) on the PRTG blog about someone having written a PRTG data source provider for [Grafana](https://grafana.com/). Grafana is excellent a creating dashboards and drawing graphs, and what's more, the end result looks good.

I set about giving it a try, and the results are pretty good so far.

I did find the installation documentation a bit lacking to start with, so here are my findings...

The install guide is [on Github here](https://github.com/neuralfraud/grafana-prtg/wiki) along with the Grafana plugin.

 * The first stumbling block for me, was that you have to use the __pass*hash*__ and not __pass*word*__ for your API user. To be fair, it does say that in the configuration wizard, I just couldn't read. You can get the __passhash__ from the `My Account` section once you're logged into PRTG.

 * Once that's done, creating a dashboard couldn't be easier.
   * Create a new dashboard
   * Add a panel of the type you want. `Graph` most likely.
   * Edit that panel, and in the `Metrics` section select PRTG as your `datasource` and then each of the `Group`, `Host`, `Sensor` and `Channel` fields will autopopulate with what's in your PRTG installation.
   * Just select what you want from the list(s) and sit back and admire your graph.

 * Remember to save your dashboard after each change. This doesn't happened automatically, and if you refresh the page you'll loose your changes.

 * If you add new things to PRTG, then you might need to refresh the Grafana page completely before those things show up in Grafana.

 * If you want a 'status table' showing you active Alarms in PRTG, for example, then you need to use the `Table` panel type in Grafana. However, you should use `raw` query mode and reference the PRTG api directly.
    * Example, URI: `table.json`, Query String: `content=sensors&columns=device,sensor,status,message,downtimesince&filter_status=4&filter_status=5&filter_status=10`. This will return all messages for Warning, Error and Unusual states. The filtering is done based on the `filter_status` options, the documentation for which I [found here](https://kb.paessler.com/en/topic/58243-filter-status-table)
    * If you dive into the `Column Styles` to color code the rows, I found I had to delete all existing rules, and create new ones before it would behave correctly.

 * In the PRTG KB there is some more examples of [getting started with the Grafana PRTG plugin](https://kb.paessler.com/en/topic/77458-are-there-alternatives-to-maps). In many ways I found that documentation more useful than what was in the Github repo for the plugin.


 Finally, here are a couple screenshots of dashboards I created.

 ![](/assets/images/2018/grafana/plex-min.jpg)

 ![](/assets/images/2018/grafana/video-encoding-min.jpg)
