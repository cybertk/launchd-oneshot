SHELL = /bin/sh -e

FORMULA = launchd-oneshot

test: test-unit test-homebrew-formula

test-unit:
	bats tests/cli-test.sh
test-homebrew-formula:
	# Setup
	cp packaging/homebrew/$(FORMULA).rb $(shell brew --repository)/Library/Formula
	chmod 640 $(shell brew --repository)/Library/Formula/$(FORMULA).rb

	# Run tests
	brew reinstall --HEAD $(FORMULA)
	# brew test $(FORMULA)
	# brew audit --strict --online $(FORMULA).rb

bootstrap:
	brew reinstall bats shellcheck
