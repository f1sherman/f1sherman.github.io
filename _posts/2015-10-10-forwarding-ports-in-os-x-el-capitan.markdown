---
layout: post
title:  "Forwarding Ports in OS X/MacOS"
permalink: "/forwarding-ports-in-os-x-el-capitan.html"
date:   2015-10-10 17:00:00
categories: howto
---

Update: I have tested this with MacOS Sierra and it works for me!

I forward local ports on my OS X machines using [pfctl][pfctl] so that I can use traditional ports for HTTP and HTTPS with [Vagrant][vagrant]
without having to start vagrant with root privleges. Recently when I updated to OS X El Capitan (10.11) I noticed that
my port forwards stopped working.

Previously I had followed some of the steps in [this gist][port-forwarding-gist], but all of those changes had
been wiped out with the upgrade. When I tried to re-apply them, a new feature called [System Integrity
Protection (SIP)][system-integrity-protection] prevented me from editing some necessary files. Also, since all of my
changes had been wiped out with this upgrade, I wanted to try to keep my changes out of existing system files as much as
possible in the hopes that they won't be wiped out with the next upgrade.

Creating an anchor file
=======================

The first file we need to add is an anchor file. This defines the ports we want to forward. Create the file in
`/etc/pf.anchors/<CUSTOM NAME>`. You can add one or many lines of the following format:

{% highlight text %}
rdr pass on lo0 inet proto tcp from any to any port <SOURCE PORT> -> 127.0.0.1 port <DESTINATION PORT>
{% endhighlight %}

Testing the anchor file
=======================

To test the anchor file, run the following command.

{% highlight bash %}
sudo pfctl -vnf /etc/pf.anchors/<CUSTOM NAME>
{% endhighlight %}

The ports won't actually be forwarded yet, this just checks the validity of your anchor file. If you see output that looks something like the below, with no errors, you're good.

{% highlight text %}
fctl: Use of -f option, could result in flushing of rules
present in the main ruleset added by the system at startup.
See /etc/pf.conf for further details.

rdr pass on lo0 inet proto tcp from any to any port = <SOURCE PORT> -> 127.0.0.1 port <DESTINATION PORT>
{% endhighlight %}

Creating a pfctl config file
============================

Once your anchor file checks out, you need to add a pfctl config file. Create this file under `/etc/pf-<CUSTOM
NAME>.conf` and add the following contents.

{% highlight text %}
rdr-anchor "forwarding"
load anchor "forwarding" from "/etc/pf.anchors/<CUSTOM NAME>"
{% endhighlight %}

Testing the config file
=======================

You can start pfctl using the below command. This will forward the ports according to your rules.

{% highlight bash %}
sudo pfctl -ef /etc/pf-<CUSTOM NAME>.conf
{% endhighlight %}

To stop forwarding ports run the same command, replacing the `e` option with `d`.

{% highlight bash %}
sudo pfctl -df /etc/pf-<CUSTOM NAME>.conf
{% endhighlight %}

Forwarding ports at startup
===========================

You can use the commands above to start port forwarding on demand if you wish, otherwise if (like me) you want to
forward ports automatically at startup you can create a [launchctl plist file][launchctl-plist]. Create a file under
`/Library/LaunchDaemons/com.apple.pfctl-<CUSTOM NAME>.plist` with the following contents:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
     <key>Label</key>
     <string>com.apple.pfctl-<CUSTOM NAME></string>
     <key>Program</key>
     <string>/sbin/pfctl</string>
     <key>ProgramArguments</key>
     <array>
          <string>pfctl</string>
          <string>-e</string>
          <string>-f</string>
          <string>/etc/pf-<CUSTOM NAME>.conf</string>
     </array>
     <key>RunAtLoad</key>
     <true/>
     <key>KeepAlive</key>
     <false/>
</dict>
</plist>
{% endhighlight %}

Add the file to startup using the following command:

{% highlight bash %}
sudo launchctl load -w /Library/LaunchDaemons/com.apple.pfctl-<CUSTOM NAME>.plist
{% endhighlight %}

Example
=======

You can find an example [here][port-forwarding-example] that forwards port 80 to 4000 and 443 to 4001.

Credits
=======

Hopefully this was helpful. Thanks to [kujohn][kujohn] for creating the excellent [gist][port-forwarding-gist] that
worked so well for me previously.

[kujohn]:                       https://gist.github.com/kujohn
[launchctl-plist]:              https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
[pfctl]:                        https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/pfctl.8.html
[port-forwarding-example]:      https://gist.github.com/f1sherman/843f85ea8e2cbcdb40af
[port-forwarding-gist]:         https://gist.github.com/kujohn/7209628
[system-integrity-protection]:  https://en.wikipedia.org/wiki/System_Integrity_Protection
[vagrant]:                      https://www.vagrantup.com
