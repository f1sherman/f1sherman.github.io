---
layout: post
title:  "New Network Host Alert"
permalink: "/new-network-host-alert.html"
date:   2017-04-17 20:00:00
categories: howto
---

For a while now I've been wanting to know when a new host joins my home network. I've (rightly) been accused of 
being a bit paranoid at times but as the sole administrator of our family's network really I just like to know 
what is going on so that I'm prepared when I get complaints about e.g. the Netflix not working. In any case, a couple
weeks ago I decided to spend an hour whipping up a script to help me do this.

The Script
==========

Here is the script.

{% highlight ruby %}
#!/usr/bin/env ruby

# Scans the network and sends an email whenever new hosts are detected. Uses MAC address to identify hosts.
# Published here: https://gist.github.com/f1sherman/1c6c5e5f31c1fab33bbd1028c15d88e1

EMAIL = 'you@example.com'

require 'set'
require 'yaml'
require 'net/smtp'

def send_alert(arpscan_info, nslookup_info)
  subject = "WARNING - A New Host Has Joined The Network"

  message = "#{arpscan_info}\n\n#{nslookup_info}"

  Net::SMTP.start('localhost', 25) do |smtp|
    mail_message = <<~EOS
      From: Notify New Hosts <#{EMAIL}>
      To: #{EMAIL}
      Subject: #{subject}
      #{message}"
    EOS

    smtp.send_message mail_message, EMAIL, EMAIL
  end
end

data_file = "#{ENV['HOME']}/.notify-new-hosts.yml"

known_hosts = File.exists?(data_file) ? YAML.load_file(data_file) : Set.new

arpscan_output = %x(arp-scan --localnet)

raise "arp-scan failed: #{arpscan_output}" unless $?.to_i == 0

host_lines = arpscan_output.split("\n").grep(/^\d+\.\d+\.\d+\.\d+/)

host_lines.each_with_object([]) do |line|
  ip, mac = line.split("\t")
  next if known_hosts.include? mac

  nslookup_output = %x(nslookup #{ip})
  send_alert line, nslookup_output
  known_hosts << mac
end

File.open data_file, 'w' do |out|
  YAML.dump known_hosts, out
end
{% endhighlight %}

Why Ruby?
=========

First you'll probably notice that the script is written in Ruby. Lately for any non-trivial script I've had to write
I've chosen Ruby over Bash. It's what I know best and almost any system I'm going to use comes with a relatively modern 
version out of the box. I find Ruby much more readable than Bash and then when I have to come back to tweak it I'm 
not wasting time brushing up on obscure Bash syntax.

Requirements
============
* Modern Ruby version
* [arp-scan](https://github.com/royhills/arp-scan) and [nslookup](https://en.wikipedia.org/wiki/Nslookup) installed
* A working local mail server listening on port 25
* Some kind of scheduling software (e.g. cron)
* Root privileges

How it works
============

The heavy lifting is handled by [arp-scan](https://github.com/royhills/arp-scan). This utility scans the local network
and reports any hosts that it finds. The result is parsed by the script and a set of known MAC addresses is serialized to a YAML 
file so that the script can remember hosts that have been seen before. When a new host is found, [nslookup](https://en.wikipedia.org/wiki/Nslookup) 
is used to try to find the hostname and then the script sends an email alert to a predefined email address.

How to run it
=============

First, the script needs to be edited to add the email address. Then the script just needs to be scheduled (e.g. via 
cron) and run as root because `arp-scan` needs to run as root. It could probably be pretty easily setup to run it as 
a normal user with some `sudoers` tricks etc. but I chose to keep it simple. Here is my crontab entry which runs the 
script once an hour (notice how I had to tweak the `PATH` so that `arp-scan` could be found):

```
# m h  dom mon dow   command
0 * * * * PATH=/usr/bin:$PATH /path/to/notify-new-hosts
```

That's it!
==========

I've been running this script for a couple weeks now. It's caught me by surprise a couple times, usually when some 
device that hasn't been used in a long time is powered up and joins the network. No bad surprises yet though, thankfully! 
Enjoy!
