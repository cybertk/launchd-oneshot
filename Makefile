SHELL = /bin/sh -e

FORMULA = launchd-oneshot

test: test-unit test-homebrew-formula

test-unit:
	sudo ./launchd-oneshot tests/job.sh
	[ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist ]
	# test-template:
	plutil -lint /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist

	sudo rm -f /tmp/launchd-oneshot.test
	sudo rm -f /usr/local/var/log/launchd-oneshot/job.sh.log
	sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist
	sleep 1
	[ -f /tmp/launchd-oneshot.test ]
	[ -f /usr/local/var/log/launchd-oneshot/job.sh.log ]
	[ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist ]
	[ ! -f /usr/local/var/launchd-oneshot/jobs/job.sh ]
	sudo launchctl list | grep com.cybertk.launchd-oneshot.job.sh.plist || true
	
test-homebrew-formula:
	# Setup
	cp $(FORMULA).rb $(shell brew --repository)/Library/Formula
	chmod 640 $(shell brew --repository)/Library/Formula/$(FORMULA).rb

	# Run tests
	brew reinstall --HEAD $(FORMULA)
	# brew test $(FORMULA)
	# brew audit --strict --online $(FORMULA).rb
