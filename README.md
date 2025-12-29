# Ethernova Status

Official uptime and latency status page for core Ethernova services. Built with Upptime, GitHub Actions, and GitHub Pages.

## Status Page

Live URL: https://ethernovadev.github.io/status/

Monitored endpoints:
- https://ethnova.net
- https://pool.ethnova.net
- https://explorer.ethnova.net
- https://rpc.ethnova.net
- https://api.ethnova.net/stats.json

Monitors are configured in `.upptimerc.yml`.

## How it works

Upptime runs scheduled checks via GitHub Actions, records response times in this repository, and publishes the status site to GitHub Pages.

## Updating monitors

Edit `.upptimerc.yml` and push to `main`. Workflows use `github.token`, so no PAT is required.

## Troubleshooting

If the status site shows an error, run these GitHub Actions workflows on `main` in order: Uptime CI, Summary CI, then Site CI.
