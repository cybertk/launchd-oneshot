# launchd-oneshot

> Run a oneshot [launchd](http://launchd.info) job at next boot/login time

[![CI Status](http://img.shields.io/travis/cybertk/launchd-oneshot/master.svg?style=flat)](https://travis-ci.org/cybertk/launchd-oneshot)

## Installation

**launchd-oneshot** can be installed via Homebrew

```bash
brew install launchd-oneshot
```

## Getting started

To add a oneshot job `script.sh` to run at next boot time

```bash
sudo launchd-oneshot script.sh
```

## Troubleshooting

logs is written to `/tmp/launchd-oneshot.log`, you can view it with

```bash
tail -f /tmp/launchd-oneshot.log
```
