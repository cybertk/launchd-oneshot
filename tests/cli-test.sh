#!/usr/bin/env bats

fixtures() {
    PATH="$BATS_TEST_DIRNAME/..:$PATH"
    FIXTURE_DIR="$BATS_TEST_DIRNAME/fixtures"

    JOBS_DIR=/usr/local/var/launchd-oneshot/jobs
}

setup() {
    echo pass
}

teardown() {
    launchctl unload /Library/LaunchAgents/com.cybertk.launchd-oneshot.job.sh.trigger.plist
    sudo launchctl unload /Library/LaunchAgents/com.cybertk.launchd-oneshot.job.sh.trigger.plist
    sudo launchctl unload /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist

    sudo rm /Library/LaunchAgents/com.cybertk.launchd-oneshot.job.sh.trigger.plist
    sudo rm /Library/LaunchDaemons/com.cybertk.launchd-oneshot.job.sh.plist

    sudo rm -f /tmp/launchd-oneshot.test
    sudo rm -f /usr/local/var/log/launchd-oneshot/job.sh.log

    sleep 1
}

fixtures

# Global setup. See https://github.com/sstephenson/bats/issues/108
@test "ensure fixtures" {
    echo pass
}

@test "installing a valid job" {
    expected_job=valid.job

    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job"
    # it should exit 0
    [ $status -eq 0 ]
    # it should installed job under $JOBS_DIR
    [ -f "$JOBS_DIR/$expected_job" ]
    # it should installed agent under /Library/LaunchDaemons/
    [ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    plutil -lint /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
}


@test "when job is complete" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job"

    # when job is loaded
    sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    sleep 1

    # it should run job
    [ -f "$expected_job_signature" ]
    # it should generating log of job
    [ -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should removed agent
    [ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should removed installed job
    [ ! -f "$JOBS_DIR/$expected_job" ]
}

@test "installing a valid job with --on-login" {
    expected_job=valid.job

    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login
    # it should exit 0
    [ $status -eq 0 ]
    # it should installed job under $JOBS_DIR
    [ -f "$JOBS_DIR/$expected_job" ]
    # it should installed agent under /Library/LaunchDaemons/
    [ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    plutil -lint /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    # it should installed corresponding trigger agent under /Library/LaunchAgents/
    [ -f /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist ]
    plutil -lint /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist
}
