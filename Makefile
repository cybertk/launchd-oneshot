SHELL = /bin/sh -e

FORMULA = launchd-oneshot

test: test-unit test-template test-homebrew-formula

test-unit:
	sudo ./launchd-oneshot tests/job.sh
	[ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist ]

	sudo rm -f /tmp/launchd-oneshot.test
	sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist
	sleep 1
	[ -f /tmp/launchd-oneshot.test ]
	# [ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist ]
	sudo launchctl list | grep com.cybertk.launchd-oneshot.job.sh.plist || true
	
test-template:
	plutil -lint job.plist.template

test-homebrew-formula:
	# Setup
	cp $(FORMULA).rb $(shell brew --repository)/Library/Formula
	chmod 640 $(shell brew --repository)/Library/Formula/$(FORMULA).rb

	# Run tests
	brew reinstall --HEAD $(FORMULA)
	brew test $(FORMULA)
	brew audit --strict --online $(FORMULA).rb
