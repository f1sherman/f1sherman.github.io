**Adding a new blog entry**

1. Add a file under `_posts` with the format `YYYY-MM-DD-title-of-my-post.markdown`
2. Run the local verification steps below
3. Commit your changes
4. Push once you are ready for the GitHub Pages workflow to deploy the site

**Testing locally**

1. `bundle install`
2. `bundle exec jekyll build`
3. `bundle exec jekyll serve`
4. Test changes at [http://localhost:4000](http://localhost:4000)

**Deployment**

The site is deployed by the GitHub Actions Pages workflow in `.github/workflows/pages.yml`.

## Renovate setup

This repository expects these GitHub repository settings for Renovate:

- secret `RENOVATE_APP_ID`
- secret `RENOVATE_APP_PRIVATE_KEY`
- variable `RENOVATE_APP_SLUG`
- secret `CLAUDE_CODE_OAUTH_TOKEN`
