---
layout: post
title:  "Automating backups of VMware Fusion VMs"
permalink: "/automating-backups-of-vmware-fusion-vms.html"
date:   2015-01-11 17:00:00
categories: howto
---

I use VMware Fusion VMs for a bunch of stuff at home: [Vagrant][vagrant] VMs, running a MythTV backend, random Linux hacking, anything you might need a Windows machine for, etc. [Snapshots][snapshots] work great for quick, local online backups, but sometimes you want a backup that you can store offsite. This post will walk you through how to script and automate the backup of a VMware Fusion Virtual Machine to a file that can be easily transferred. Before I get into this post I want to make it clear that while I am an employee of VMware, this is a personal blog and this post is being written on my behalf, not that of my employer.

Shutting down the Virtual Machine
=================================

Per the [official documentation][fusion-backup], to take a full backup of a Fusion VM the .vmwarevm bundle must be copied while the VM is shut down. Since directory copies are non-atomic, this ensures that the VM is in a valid state. To do this, the [vmrun][vmrun] command can be used. You can find this command inside the `VMware Fusion.app` bundle, typically at `/Applications/VMware Fusion.app/Contents/Library/vmrun`. You will also need to know the path to the VM's vmx file.

{% highlight bash %}
'/Applications/VMware Fusion.app/Contents/Library/vmrun' stop '/path/to/file.vmx' soft
{% endhighlight %}

This command will fail if the VM is already shut down, so when putting this in a script (which we'll be doing) it helps to check to make sure the VM is running before issuing it.

{% highlight bash %}
VMRUN='/Applications/VMware Fusion.app/Contents/Library/vmrun'
VMX='/path/to/file.vmx'
if "$VMRUN" list | grep --quiet "$VMX"; then
  "$VMRUN" stop "$VMX" soft
fi
{% endhighlight %}

Creating the backup file
========================

Once the VM is backed up, the .vmwarevm bundle is ready to be copied. This is a good time to compress the bundle to a file to make it more portable. Note: I typically like to have my backup directory on a network volume to keep me from losing both the backup and the VM if the main disk has issues.

{% highlight bash %}
cd '/path/to/bundle.vmwarevm'
tar -czpf "/path/to/backup/directory/fusion-backup-`date +%Y%m%d-%H%M%S`.tar.gz" *
{% endhighlight %}

Since the VM must remain shut down until these files are done being copied, another option to minimize VM downtime would be to rsync the .vmwarevm bundle to an intermediate directory, start the VM, then compress the bundle. 

{% highlight bash %}
# The following command must be run as root
rsync --archive --delete '/path/to/bundle.vmwarevm/' '/path/to/intermediate/directory' 
# Start the VM (we’ll cover this in the next section)
cd '/path/to/intermediate/directory'
tar -czpf "/path/to/backup/directory/fusion-backup-`date +%Y%m%d-%H%M%S`.tar.gz" *
{% endhighlight %}

The downside of this is that it can be a lot harder on your disks - since I use SSDs and I don't really care if my VM is down for a few extra minutes I stick with the former.

Starting the VM
===============

Similar to shutting down, we can start the VM with the `vmrun` utility.

{% highlight bash %}
'/Applications/VMware Fusion.app/Contents/Library/vmrun' start '/path/to/file.vmx'
{% endhighlight %}

It can be helpful to use the trap function to ensure that the VM gets started up even if something else in the script causes it to exit.

{% highlight bash %}
trap startvm EXIT
function startvm {
  '/Applications/VMware Fusion.app/Contents/Library/vmrun' start '/path/to/file.vmx'
}
{% endhighlight %}

Pruning stale backups
=====================

In order to preserve space, it is a good idea to prune old backups that are no longer needed. Note: the below assumes that the backup directory is used exclusively for backups of this VM. If for whatever reason you have other files in the backup directory this will not work as expected and may delete files that you don't want deleted.

{% highlight bash %}
cd '/path/to/backup/directory'
# Delete all but the 3 most recent backups
(ls -t | head -n 3; ls) | sort | uniq -u | xargs rm
{% endhighlight %}

Wrapping it up into a script
============================

Here is the full script for the above. Note: you'll need to make the script executable to run it (e.g. `chmod +x /path/to/backup-fusion.sh`).

{% gist c3bfd69600ce81e3d982 %}

Scheduling backups
==================

There are 2 built-in options for scheduling jobs in OS X, launchd and cron. Per the [documentation][os-x-scheduled-tasks], cron is deprecated so we'll use launchd. To schedule a launchd task, create a `.plist` file in `~/Library/LaunchAgents/`, e.g. `~/Library/LaunchAgents/com.vmware.backupfusion.plist`. Check the [documentation][plist-docs] for more information on the format. The following example schedules a task to run every Monday at 3am.

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.vmware.backupfusion</string>

    <key>ProgramArguments</key>
    <array>
        <string>/path/to/backup-fusion.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>

        <key>Minute</key>
        <integer>0</integer>

        <key>Weekday</key>
        <integer>1</integer>
    </dict>
  </dict>
</plist>
{% endhighlight %}

Run the following command to add the `.plist` file to the scheduler.

{% highlight bash %}
launchctl load ~/Library/LaunchAgents/com.vmware.backupfusion.plist
{% endhighlight %}

Restoring from backup
=====================

Restoring from backup is pretty easy. These are just files so you can extract them wherever you want, then point Fusion at them via `File --> Open...`.

{% highlight bash %}
cd /path/to/target/directory
tar -xzvf '/path/to/backup/file.tar.gz'
{% endhighlight %}

[fusion-backup]:        http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1013628
[os-x-scheduled-tasks]: https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/ScheduledJobs.html
[plist-docs]:           https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html#//apple_ref/doc/uid/TP40001762-104142
[snapshots]:            http://pubs.vmware.com/fusion-6/index.jsp?topic=%2Fcom.vmware.fusion.help.doc%2FGUID-4C90933D-A31F-4A56-B5CA-58D3AE6E93CF.html
[vagrant]:              https://www.vagrantup.com
[vmrun]:                http://www.vmware.com/pdf/vix180_vmrun_command.pdf
