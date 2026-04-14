# Blog modernization walkthrough after merge fix

*2026-04-14T13:14:41Z by Showboat 0.6.1*
<!-- showboat-id: 206fc192-9103-45ad-b59c-6bdbad8b33ec -->

This walkthrough reflects the current blog-modernization branch after resolving the Gemfile.lock merge conflict with origin/main. It shows the homepage branding cleanup plus the local Mermaid preview draft used to verify code block and diagram rendering before publishing the OpenClaw post.

```bash
bundle exec jekyll build --drafts
```

```output
Configuration file: /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization/_config.yml
To use retry middleware with Faraday v2.0+, install `faraday-retry` gem
            Source: /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization
       Destination: /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization/_site
 Incremental build: disabled. Enable with --incremental
      Generating... 
DEPRECATION WARNING [import]: Sass @import rules are deprecated and will be removed in Dart Sass 3.0.0.

More info and automated migrator: https://sass-lang.com/d/import

   ╷
37 │   "base",
   │   ^^^^^^
   ╵
    /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization/css/main.scss 37:3  root stylesheet
DEPRECATION WARNING [import]: Sass @import rules are deprecated and will be removed in Dart Sass 3.0.0.

More info and automated migrator: https://sass-lang.com/d/import

   ╷
38 │   "layout",
   │   ^^^^^^^^
   ╵
    /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization/css/main.scss 38:3  root stylesheet
DEPRECATION WARNING [import]: Sass @import rules are deprecated and will be removed in Dart Sass 3.0.0.

More info and automated migrator: https://sass-lang.com/d/import

   ╷
39 │   "syntax-highlighting";
   │   ^^^^^^^^^^^^^^^^^^^^^
   ╵
    /Users/brian/.config/superpowers/worktrees/f1sherman.github.io/blog-modernization/css/main.scss 39:3  root stylesheet
                    done in 0.718 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
```

```bash
bundle exec ruby -e "require \"rexml/document\"; puts REXML::VERSION"
```

```output
3.4.4
```

Homepage after removing the repeated visible site-title heading from the hero section.

```bash {image}
![Homepage after branding cleanup](tmp/pr-walkthrough/homepage-updated.png)
```

![Homepage after branding cleanup](e0b87a11-2026-04-14.png)

Local draft post showing the styled shell, a fenced bash command, and a rendered Mermaid diagram. This draft remains unpublished under _drafts_.

```bash {image}
![Local Mermaid preview draft](tmp/pr-walkthrough/mermaid-draft.png)
```

![Local Mermaid preview draft](50c9b3f8-2026-04-14.png)

```bash
git log --oneline --decorate -n 4
```

```output
f557c9c (HEAD -> blog-modernization, origin/blog-modernization) Resolve Gemfile.lock merge conflict
97805fa Add a local Mermaid preview draft
38047e9 Refine homepage branding copy
b1ae1ae Run Pages workflow on pull requests
```
