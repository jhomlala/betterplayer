# Hasoft.pl Static Website

This is the source code for [hasoft.pl](https://hasoft.pl), built with Jekyll.

## Local Development

1.  **Install Ruby**: Make sure you have Ruby installed.
2.  **Install Bundler**: `gem install bundler`
3.  **Install Dependencies**: `bundle install`
4.  **Run Locally**: `bundle exec jekyll serve`
5.  Open `http://localhost:4000` in your browser.

## Deployment

The site is configured to deploy automatically via GitHub Actions to `home.pl` (or any FTP server).

### Configuration

You need to add the following secrets to your GitHub Repository (`Settings > Secrets and variables > Actions`):

*   `FTP_SERVER`: The FTP host (e.g., `ftp.hasoft.pl` or your IP).
*   `FTP_USERNAME`: Your FTP username.
*   `FTP_PASSWORD`: Your FTP password.

The workflow will build the site and upload the contents of the `_site` directory to your server root.

## Adding Articles

To add a new article, create a new Markdown file in the `_posts` directory with the format `YYYY-MM-DD-title.md`.
