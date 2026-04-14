# Blog Modernization Design

Date: 2026-04-13
Status: Approved for planning

## Summary

Modernize the existing Jekyll blog without changing its information architecture. The refreshed site will keep the current shape of the experience: homepage with chronological posts, individual post pages, and RSS. The work will focus on visual polish, updated dependencies and deployment, better long-form reading ergonomics, and Mermaid diagram rendering for future posts.

The site will remain intentionally small. This design does not add new top-level pages, tags, categories, archives, or other content surfaces. It also does not publish the unpublished OpenClaw post currently living in `tmp/openclaw-post.md`.

## Current State

The repository is a small Jekyll site using:

- `index.html` as a simple chronological post list
- `_posts/` for individual posts
- `_layouts/` and `_includes/` that are still close to the older default Jekyll starter structure
- Sass split across `css/main.scss` and `_sass/`
- `github-pages` gem and the old GitHub Pages compatibility model

The current site works, but it still looks and behaves like a default starter blog:

- generic default-theme visual language
- limited typographic hierarchy
- heavy footer relative to the amount of content
- minimal metadata and semantic polish
- no Mermaid rendering support on the generated site

## Goals

- Keep the site structure exactly the same at a user-facing level: homepage, individual post pages, and RSS feed
- Preserve existing post URLs and content files
- Refresh the visual design so the site feels current, authored, and intentional
- Improve readability on desktop and mobile
- Modernize the build and deployment setup
- Add Mermaid diagram rendering for published posts and pages that include Mermaid code fences

## Non-Goals

- Do not publish `tmp/openclaw-post.md` in this change
- Do not add About, Archive, tag, or category pages
- Do not migrate to a different static site generator
- Do not rewrite old post content except where a compatibility fix is required
- Do not change existing permalink structure

## Chosen Approach

Three approaches were considered:

- Minimal patch: reskin the current theme and add Mermaid with minimal structural changes
- Custom refresh on existing Jekyll: keep Jekyll and the site shape, but rebuild the presentation and deployment cleanly
- Replatform: move to a different static site generator or framework

The chosen approach is the custom refresh on existing Jekyll.

Why this approach:

- It preserves the small-repo simplicity that suits the site
- It keeps content migration risk near zero
- It allows a real visual refresh instead of a superficial skin
- It avoids the long-term constraint of the legacy GitHub Pages hosted environment

## Site Structure

The live site will continue to expose only the following surfaces:

- `/` as the homepage post index
- existing post permalinks for all published posts
- `/feed.xml` for RSS

No additional pages will be introduced in this modernization branch.

## Visual Direction

The approved visual direction is the "A3" hybrid from the design comparison:

- editorial layout structure
- cool, technical color palette
- restrained navigation and topical framing
- more intentional hierarchy without turning the blog into a product or marketing site

The intended feel is:

- personal technical notebook
- calm and readable
- more distinctive than a starter theme
- still pragmatic and code-friendly

### Layout Principles

- The homepage remains a post list, but the top of the page will have a more composed hero/header treatment
- The post index should still scan quickly and remain obviously chronological
- Individual posts should read as long-form writing, not as cards in an app shell
- The header and footer should become lighter and more proportionate to the amount of content on the site

### Typography

Typography should carry most of the visual personality.

- Headings and major post titles: serif-forward display treatment
- Navigation, metadata, bylines, and utility text: clean sans-serif
- Body text: optimized for long reading, not condensed UI styling

The implementation should use `Newsreader` for major headings and post titles, and `IBM Plex Sans` for body text, metadata, navigation, and other UI text. Monospace code styling remains separate from this pairing.

### Color System

The current default-theme blue should be replaced with a cooler paper-and-slate palette:

- pale blue-gray or paper background
- dark ink text
- subtle borders and separators
- one restrained accent color for links and interactive emphasis

The palette should remain light. This redesign is not a dark-mode-first treatment.

## Template And Styling Changes

The implementation should update the existing templates rather than replace the content model.

Primary files likely to change:

- `_layouts/default.html`
- `_layouts/post.html`
- `index.html`
- `_includes/head.html`
- `_includes/header.html`
- `_includes/footer.html`
- `css/main.scss`
- `_sass/_base.scss`
- `_sass/_layout.scss`
- `_sass/_syntax-highlighting.scss`

### Homepage Expectations

- Preserve chronological listing of posts
- Add a stronger top-of-page introduction and hierarchy
- Keep the page obviously a blog index, not a landing page
- Improve spacing, metadata treatment, and link affordances

### Post Page Expectations

- Better reading width and spacing rhythm
- Clearer title, date, and content separation
- Improved heading hierarchy
- Cleaner code block, table, blockquote, and image styling
- Better behavior on narrow/mobile screens

### Footer Expectations

- Reduce visual weight compared to the current footer
- Keep identity and useful links
- Avoid large multi-column treatment unless it still feels proportionate on a very small-content site

## Mermaid Rendering Design

GitHub proper can render Mermaid in repository Markdown views, but the generated GitHub Pages site cannot do so automatically with the current setup. The modernized site will add Mermaid support as a client-side enhancement.

### Rendering Strategy

- Keep authoring diagrams in standard fenced Markdown blocks using the `mermaid` info string
- Let Jekyll render those fences into HTML code blocks during build
- On the client, detect Mermaid code blocks in the rendered page
- Replace those code blocks with Mermaid-rendered diagrams after the page loads

### Implementation Strategy

Use a pinned Mermaid browser module loaded on the site itself, initialized only when Mermaid blocks are present.

Required shape:

- use an exact Mermaid version in the committed script URL
- do not add a bundler or Node-based asset pipeline for this feature
- scope initialization to pages that actually contain Mermaid fences

This approach is preferred over a larger JS toolchain because the site is intentionally small and does not otherwise justify frontend build complexity.

### Verification Strategy

Because the OpenClaw post is not being published yet, Mermaid verification must happen in local preview without adding a new public page to the site. Implementation may use one of these approaches during testing:

- a temporary local-only preview page
- a temporary local copy of the unpublished post wired into preview only
- another non-committed Mermaid fixture used purely for browser verification

The committed branch should not add a new published content page solely for Mermaid testing.

## Build And Deployment Design

The site should move away from depending on the legacy GitHub Pages hosted Jekyll environment.

### Build Direction

- Build the site in GitHub Actions
- Deploy the generated static output to GitHub Pages using the current recommended Pages workflow
- Use the repository's own gem versions as the source of truth

### Dependency Direction

Replace dependence on the `github-pages` meta-gem with directly declared gems that match the actual site needs.

Base dependency direction:

- `jekyll`
- `jekyll-sitemap`
- `jekyll-gist`
- `webrick`

Additional gems are allowed only if they are required by a concrete feature implemented in this branch.

This keeps the dependency set smaller, clearer, and easier to update.

## Metadata And Semantics

The modernization should improve document quality without changing site structure.

Expected improvements:

- cleaner page titles and descriptions
- better semantic HTML in templates
- improved accessibility for navigation and content structure
- more modern treatment of canonical and feed metadata

These changes should remain proportional to the project. The site does not need a full CMS-style metadata system.

## Testing And Validation

Implementation is not complete until the refreshed site is verified locally and through the build pipeline.

Minimum validation:

- `bundle install`
- `bundle exec jekyll build`
- `bundle exec jekyll serve`
- homepage renders correctly
- at least one existing post renders correctly
- Mermaid rendering works in local preview on a non-published test fixture
- GitHub Actions Pages build succeeds

Validation should cover:

- desktop and mobile layout sanity
- code blocks and tables
- old posts with existing images and formatting
- pages without Mermaid content still behaving normally

## Risks

- Old Jekyll starter markup may have hidden assumptions that surface when the CSS is modernized
- Dropping the `github-pages` meta-gem may expose plugin or configuration drift that needs cleanup
- Mermaid initialization can be brittle if the rendered HTML shape differs from assumptions made by the script
- Older posts may reveal edge cases in markdown styling once spacing and widths change

## Out-Of-Scope Follow-Up Work

The following are reasonable future follow-ups, but they are not part of this design:

- publish the OpenClaw / BlueBubbles / cmdrunner post
- add archive or About pages
- add search
- add taxonomy pages
- add dark mode
- migrate to a different static site generator

## Success Criteria

This modernization is successful when all of the following are true:

- the site still has the same public structure as before
- the refreshed design feels modern and intentionally authored
- existing post URLs remain stable
- local and CI builds are reproducible with the repo-controlled toolchain
- Mermaid diagrams can render on the deployed site
- no unpublished OpenClaw content is made public as part of this change
