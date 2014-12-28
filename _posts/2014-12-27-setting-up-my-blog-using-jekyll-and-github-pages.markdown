---
layout: post
title:  "Setting up my blog using Jekyll and GitHub Pages"
permalink: "/setting-up-my-blog.html"
date:   2014-12-27 20:04:49
categories: howto
---
I was listening to a recent [Ruby Rogues][ruby-rogues] podcast on [Marketing Yourself as a Software Developer][marketing-podcast]. During this episode [John Sonmez][sonmez-twitter], who runs the site [Simple Programmer][simple-programmer] gives some great reasons as to why you should market yourself as a software developer, as well as some excellent ways to do that. One of the ideas was to create a blog. This is something I've wanted to do for a long time, but I've never really enjoyed writing and I've always felt like it would be a chore to have to come up with topics. John had a great idea related to this that is simple but that I'd never thought of: just blog about what you're already doing or working on. I decided I'm going to give this a try. Normally I don't do New Year's resolutions because I find it easier to start making changes right away, but the timing is right. This year my New Year's resolution is going to be to write at least 10 blog posts in 2015. That seems pretty doable. So, predictably, my first post is going to be about creating my blog. Here goes.

GitHub Pages
============

[GitHub Pages][github-pages] seemed like a good choice for hosting my blog for a couple of reasons:

1. I trust GitHub, and they will host my blog for free, so no messing around with a VPS or anything like that
2. They have built-in [Jekyll][jekyll] support, which is a well-known blogging platform

The initial setup with Pages was pretty simple and only took a few minutes. You can read the guide [here][github-pages] so I won't bore you with the details. After pushing my initial commit to my repository and waiting a few minutes for the changes to show up, I had a working blog at f1sherman.github.io.

![Hello World](/images/hello-world.png)

Custom Domain
=============

I wanted to host my blog on my personal domain. This was pretty easy and you can find instructions [here][custom-domain]. Basically it involves dropping a `CNAME` file into your repository and setting up the CNAME with your DNS provider.

![CNAME](/images/cname.png)

Jekyll
======

Jekyll seemed like a good choice for a blogging platform because it is supported natively by GitHub Pages and supports [Markdown][markdown], which I already use often. Initial setup with Jekyll was a combination of the steps listed in the [GitHub Pages documentation][github-jekyll] as well as the [Jekyll documentation][jekyll-docs]. After a few minutes I had some scaffolding to build on.

![Scaffolding](/images/scaffolding.png)

Theme
=====

I decided to stick with the base Jekyll theme for now, mostly because I wanted to start generating content as soon as possible and this seemed like it could be a rabbit hole. At some point I'll probably rip it out and try something more fancy.

Google Analytics
================

[Google Analytics][google-analytics] is a great, free way to track the popularity of your site. I created a `_includes/google-analytics.html` fragment with the GA tracking code and added that to `_layouts/default.html`.

{% highlight html %}
<SNIP>

  <body>
    {{ "{% include google-analytics.html " }}%}

<SNIP>
{% endhighlight %}


[custom-domain]:      https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/
[github-jekyll]:      https://help.github.com/articles/using-jekyll-with-pages/
[github-pages]:       https://pages.github.com/
[google-analytics]:   http://www.google.com/analytics/
[jekyll]:             http://jekyllrb.com
[jekyll-docs]:        http://jekyllrb.com/docs/home/
[markdown]:           https://en.wikipedia.org/wiki/Markdown
[marketing-podcast]:  http://devchat.tv/ruby-rogues/187-marketing-yourself-as-a-software-developer-with-john-sonmez
[ruby-rogues]:        http://rubyrogues.com
[simple-programmer]:  http://simpleprogrammer.com
[sonmez-twitter]:     https://twitter.com/jsonmez
