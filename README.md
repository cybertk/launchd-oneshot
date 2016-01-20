# launchd-oneshot

> Run a oneshot job at next boot/login time on OSX

[![CI Status](http://img.shields.io/travis/cybertk/launchd-oneshot/master.svg?style=flat)](https://travis-ci.org/cybertk/launchd-oneshot)

## Installation

**launchd-oneshot** can be installed via Homebrew

```bash
brew install https://raw.githubusercontent.com/cybertk/launchd-oneshot/master/launchd-oneshot.rb
```

## Getting started

To add a oneshot job `script.sh` to run at next boot time

```bash
sudo launchd-oneshot script.sh
```

To add a oneshot job `script.sh` to run at next user login time

```bash
sudo launchd-oneshot script.sh --on-login
```

To add a oneshot job `script.sh` to run at next user login time with root, and **launchd-oneshot** will pass current login user as `$1` to `script.sh`

```bash
sudo launchd-oneshot script.sh --on-login-as-root
```


## Troubleshooting

logs is written to `/tmp/launchd-oneshot.log`, you can view it with

```bash
tail -f /tmp/launchd-oneshot.log
```

## How does launchd-oneshot work?

**launchd-oneshot** installs a **launchd agent** under `/Library/LaunchDaemons` for each job. When agent is running, it will start **launchd-oneshot** in **RUN** mode, which will execute the origin job and remove the **launchd agent** when job is completed.

For `--on-login` job, in order to run the job as root, **launchd-oneshot** will install a trigger **launchd agent** under `/Library/LaunchAgents` in addition. When user login, the trigger agent will start running. And it will trigger the **launchd agent** under `/Library/LaunchDaemons` to run through launchd's `KeepAlive:OtherJobEnabled` mechanism.
