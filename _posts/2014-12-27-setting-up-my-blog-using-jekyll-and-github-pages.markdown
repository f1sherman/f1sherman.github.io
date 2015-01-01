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

Social Media Icons
==================

I wanted to add some social media links to my footer (in addition to the github and twitter links that are included with jekyll), but had some trouble finding SVGs that would work with the default theme. Eventually I stumbled upon [this set of svgs][social-media-icons] which was helpful not only for the SVGs themselves, but also for the idea to get icons from [iconmonstr][iconmonstr] and compress them using [this SVG Editor][svg-editor] for icons that weren't included. See the [markup on github][social-media-markup] for the code.

![Social Media Icons](/images/social-media-icons.png)

Comments
========

I decided to use [disqus][disqus] for commenting because it was familiar and easy to setup. I used the wizard on the disqus site to set up the commenting account, then added the code that it provided to [_includes/disqus.html][disqus-html] and included it in [_layouts/post.html][disqus-include].

![Disqus Comments](/images/disqus.png)

About Page
==========

I [removed][remove-about-commit] the About page that Jekyll creates because I wasn't ready to tackle this yet and I wanted to get the site up as soon as possible. I may add this back later.

Tweet Button
============
I added the [Tweet button resource from Twitter][tweet-button] to the post layout to make it easy for readers to tweet my posts.

![Tweet Button](/images/tweet-button.png)

[custom-domain]:        https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/
[disqus]:               https://disqus.com/
[disqus-html]:          https://github.com/f1sherman/f1sherman.github.io/blob/f79093961e1eb5b434941d1b286f6baa0da381d3/_includes/disqus.html
[disqus-include]:       https://github.com/f1sherman/f1sherman.github.io/blob/f79093961e1eb5b434941d1b286f6baa0da381d3/_layouts/post.html#L17
[github-jekyll]:        https://help.github.com/articles/using-jekyll-with-pages/
[github-pages]:         https://pages.github.com/
[google-analytics]:     http://www.google.com/analytics/
[iconmonstr]:           http://iconmonstr.com
[jekyll]:               http://jekyllrb.com
[jekyll-docs]:          http://jekyllrb.com/docs/home/
[markdown]:             https://en.wikipedia.org/wiki/Markdown
[marketing-podcast]:    http://devchat.tv/ruby-rogues/187-marketing-yourself-as-a-software-developer-with-john-sonmez
[remove-about-commit]:  https://github.com/f1sherman/f1sherman.github.io/commit/125b5580d79988efc803772ed3a8e314e099ed46
[ruby-rogues]:          http://rubyrogues.com
[simple-programmer]:    http://simpleprogrammer.com
[social-media-icons]:   http://codepen.io/ruandre/pen/howFi
[social-media-markup]:  https://github.com/f1sherman/f1sherman.github.io/blob/1544d0076db82b050951f08fc7c70bb4f11ccd14/_includes/footer.html#L17-L68
[sonmez-twitter]:       https://twitter.com/jsonmez
[svg-editor]:           http://petercollingridge.appspot.com/svg-editor
[tweet-button]:         https://about.twitter.com/resources/buttons#tweet


