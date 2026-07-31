---
layout: post
title: "How I Use AI Agents to Run My Home Network"
permalink: "/how-i-use-ai-agents-to-run-my-home-network.html"
date: 2026-07-30 20:42:54 -0500
author: Brian John
categories: [howto]
---

## Introduction

Anyone that knows me pretty well knows that I am a constant tinkerer, and I love solving Engineering problems, and just generally learning about technology. So over the years, I've naturally accumulated a lot of random projects and things on my home network. A small subset of examples:
* An OpenClaw instance on a MacMini
* An [Apache Guacamole](https://guacamole.apache.org/) instance so that I can remote in to our Windows PCs
* A [Unifi server](https://ui.com/download/software/unifi-os-server) for managing my network
* [Home Assistant](https://www.home-assistant.io/) for Home Automation
* A couple custom Minecraft servers with mods for my kids and their friends to play on
* A [Nextcloud](https://nextcloud.com/) instance for collaboration and to help run my paperless office
* A [Forgejo](https://forgejo.org/) server for storing my private repositories A [Huginn](https://github.com/huginn/huginn) server for monitoring random things on the Internet
* On-site and Off-site NAS servers

Almost everything is provisioned using [Ansible](https://ansible.com) with regular backups of all important data to the NAS's.

As you can imagine, keeping all of this stuff running and up to date is a bit of a part time job. It seems like something is always running out of disk space or memory, or just broken due to automated updates or who knows what. As I've been getting more and more into running AI agents at work, I've kind of incrementally created some agents that help me keep this all up and running without taking too much of my time. At this point I think I've build up enough stuff that it's worth writing about.

Before I get into the agents, let me talk about a couple of tools that are at the center of all of them: the Alert Tracker and Memento.

## Alert Tracker

Anything reasonably important on my network has built-in monitoring. Most stuff is monitored by [monit](https://mmonit.com/monit/), but there are a few random other things like cronjob failure alerts, etc. All of the alerts go into a really basic Alert Tracker app that Codex built for me. Instead of relying on my email to know what alerts have gone off, the Alert Tracker keeps everything aggregated in one place where I can see what alerts have been firing and what their status is.

![Alert Tracker List Page](/images/alert-tracker-list-page.png)

I can drill into each alert to see the status of the alert, what repairs have been attempted, details, etc.

![Alert Tracker Detail Page](/images/alert-tracker-detail.png)

![Alert Tracker Repairs](/images/alert-tracker-repairs.png)

## Memento

With all of the different agents working on my network, they need a way to remember what they've tried in the past and what has worked and what hasn't. For this, I created a lightweight memory service called Memento. Memento has no UI, it's a simple web service that agents are prompted to query before attempting a fix for an alert. It's effectively a simple database that keeps an updated inventory of all coding sessions and links them to the PRs they created and the alerts that they fixed. Annotations can be added to a PR node after the fact, like if a fix turned out to not work the agent is instructed to go back to that PR node and add an annotation describing what went wrong. This has built up a knowledge base over time of what worked and what didn't, which makes the agents smarter about what to try when they see similar or repeated alerts, and fixes an issue I had early on where agents kept trying to fix things in the same broken ways.

![Memento Data Model](/images/memento-data-model.png)

## Alert Worker

To help me deal with all of the alerts that go off, I've created an Alert Worker agent. It wakes up on a schedule, looks at all of the alerts that have fired since its last wake, and gets to work on them. It is smart enough to aggregate alerts that are duplicates, and it also scans recent changes to the Ansible repository to see if something has already been fixed.

Security is super important to me so the Alert Worker (and all the other agents, actually) is extremely locked down. It has no network access other than to connect to the AI provider and the Command Proxy (I talked about the Command Proxy already [here](/my-openclaw-setup.html)). Through the Command Proxy it can run some allow-listed troubleshooting commands to get more information on what might have caused an alert, and it can submit pull requests to make changes. Sometimes it will submit changes to its troubleshooting commands so it can get more detail on an alert. None of the pull requests get merged without my review (yet). This limits the effectiveness of the Alert Worker a bit, but I feel good about the security of it.

Since the Alert Worker can create PRs that trigger CI, the CI runners are also locked down from a network standpoint.

## Issue Worker

Issue Worker is a lot like Alert Worker, except it works on Forgejo and Github Issues. Sometimes I have an idea for something I want to work on later, or I find an issue and want to make a note of it, but I'm not ready to deal with it right now. In that case, I have my agent log an issue and I can add a label to it that causes the Issue Worker to pick it up and work on it. Frankly I don't use the Issue Worker all that much - I kind of like being hands on right now with my agents, but I should probably use it more often.

## Reviewer

Of course every PR gets automatically reviewed. I've found that GPT 5.6 Sol in extra high effort mode seems to be exceptionally good at finding issues in PRs and avoiding much noise. I lifted the prompt pretty much verbatim from the open-source [Codex CLI Repository](https://github.com/openai/codex) and it works great. Each time that a PR is updated the Reviewer agent will take a review pass on the diff, and to keep the noise down it aggregates all of its top-level review feedback in a sticky comment. In order to keep this highly reliable I've made as much of it deterministic as possible. All needed context is fed into the agent so it doesn't have to go poking around to e.g. see the diff, and it simply outputs a JSON blob with all of the feedback, then a script parses the JSON and posts the comments on the PR.

![Automated Review](/images/automated-review.png)

## Risk Analyzer

One thing I've been toying with recently is a PR Risk Analyzer bot. It's job is subtly different from the Reviewer. Instead of looking for issues, the Risk Analyzer's job is simply to determine the potential blast radius of each PR. My goal is to eventually allow automated merging of PRs based on risk tier. So far though this agent still needs a lot of tweaking and its output isn't all that useful.

![Risk Analysis](/images/risk-analysis.png)

## PR Upkeeper

With all of the automated review feedback coming in it would be really time-intensive for me to address all of it, so I have a "PR Upkeeper" agent that wakes up on an interval, looks at all open PRs, and addresses any issues with them (review feedback, failing checks, merge conflicts). It works pretty well, but I think it could be better. For example, it doesn't currently use the original session that built the PR as context for addressing feedback, so it's kind of too agreeable in addressing review feedback and doesn't push back enough. I need to fix that. Over time this agent has become more and more sophisticated in what it can handle - for example if it encounters a failed check due to a flake, it re-runs the check in the current PR context and logs an alert so that the Alert Worker picks it up later and puts in a permanent fix.

## Renovate

Just keeping dependencies up to date with everything going on here could be a real chore. Thankfully I've found [Renovate](https://github.com/renovatebot/renovate) to be extremely flexible and has met pretty much all of my needs. It has a built-in dependency cooldown to mitigate against supply-chain attacks, and can handle upgrading pretty much everything from docker images to ruby gems. Renovate PRs are actually the only PRs that currently auto-merge based on passing checks and a passing automated review.

## Conclusion

This is a lot, I know. It kind of all built up organically over time as my family's use cases have expanded and I've constantly asked myself the question "how can I spend less time on this?". In the end I'm not sure if I'm actually saving any time, but it's actually been pretty fun building this all up and I'm learning a lot. Coding agents are so fun.

Oh, and you might think that I'm swimming in LLM provider debt but actually this all runs pretty efficiently and probably only uses about 20% of my $200/mo Codex plan at steady state in a given week, so I still have plenty of tokens for other stuff.

Well, I hope this was useful for someone. It was kind of fun to go through all of this stuff that I've built and get a big picture view, and it's given me some ideas for ways that it could be improved.
