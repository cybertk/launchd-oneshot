#!/usr/bin/env bats

fixtures() {
    PATH="$BATS_TEST_DIRNAME/..:$PATH"
    FIXTURE_DIR="$BATS_TEST_DIRNAME/fixtures"
    SCRIPT_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/launchd-oneshot"

    JOBS_DIR=/usr/local/var/launchd-oneshot/jobs
    LOGS_DIR=/usr/local/var/log/launchd-oneshot
}

setup() {
    echo pass
}

teardown() {
    launchctl unload /Library/LaunchAgents/com.cybertk.launchd-oneshot.*.plist
    sudo launchctl unload /Library/LaunchAgents/com.cybertk.launchd-oneshot.*.plist

    sudo rm /Library/LaunchAgents/com.cybertk.launchd-oneshot.*.plist
    sudo rm /Library/LaunchDaemons/com.cybertk.launchd-oneshot.*.plist

    sudo rm -f /tmp/launchd-oneshot*
    sudo rm -f /usr/local/var/log/launchd-oneshot/*

    sleep 1
}

fixtures

# Global setup. See https://github.com/sstephenson/bats/issues/108
@test "ensure fixtures" {
    echo pass
}

@test "installing a valid job" {
    expected_job=valid.job
    expected_agent=/Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist

    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job"
    # it should exit 0
    [ $status -eq 0 ]
    # it should installed job under $JOBS_DIR
    [ -f "$JOBS_DIR/$expected_job" ]
    # it should installed agent under /Library/LaunchDaemons/
    [ -f "$expected_agent" ]
    plutil -lint "$expected_agent"
    # it should have correct key/values in agent
    defaults read "$expected_agent" Label | grep "^com.cybertk.launchd-oneshot.$expected_job$"
    defaults read "$expected_agent" Program | grep "^$SCRIPT_PATH$"
    defaults read "$expected_agent" ProgramArguments | wc -l | grep "4"
    defaults read "$expected_agent" ProgramArguments | grep "$SCRIPT_PATH"
    defaults read "$expected_agent" ProgramArguments | grep "$expected_job"
    defaults read "$expected_agent" EnvironmentVariables | grep '"LAUNCHD_ONESHOT_JOB" = 1;'
    defaults read "$expected_agent" KeepAlive | grep "SuccessfulExit = 0;"
    defaults read "$expected_agent" RunAtLoad | grep "^1$"
    defaults read "$expected_agent" StandardErrorPath | grep "^$LOGS_DIR/$expected_job.log$"
    defaults read "$expected_agent" StandardOutPath | grep "^$LOGS_DIR/$expected_job.log$"
}


@test "load a valid --on-boot job" {
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
    expected_agent=/Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    expected_trigger_agent=/Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist

    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login
    # it should exit 0
    [ $status -eq 0 ]
    # it should installed job under $JOBS_DIR
    [ -f "$JOBS_DIR/$expected_job" ]
    # it should installed agent under /Library/LaunchDaemons/
    [ -f "$expected_agent" ]
    plutil -lint "$expected_agent"
    # it should have correct key/values in agent
    defaults read "$expected_agent" Label | grep "^com.cybertk.launchd-oneshot.$expected_job$"
    defaults read "$expected_agent" Program | grep "^$SCRIPT_PATH$"
    defaults read "$expected_agent" ProgramArguments | wc -l | grep "4"
    defaults read "$expected_agent" ProgramArguments | grep "$SCRIPT_PATH"
    defaults read "$expected_agent" ProgramArguments | grep "$expected_job"
    defaults read "$expected_agent" WatchPaths | grep "/tmp/com.cybertk.launchd-oneshot.$expected_job.option"
    defaults read "$expected_agent" EnvironmentVariables | grep '"LAUNCHD_ONESHOT_JOB" = 1;'
    defaults read "$expected_agent" KeepAlive | grep "SuccessfulExit = 0;"
    defaults read "$expected_agent" RunAtLoad | grep "^1$"
    defaults read "$expected_agent" StandardErrorPath | grep "^$LOGS_DIR/$expected_job.log$"
    defaults read "$expected_agent" StandardOutPath | grep "^$LOGS_DIR/$expected_job.log$"
    # it should installed corresponding trigger agent under /Library/LaunchAgents/
    [ -f "$expected_trigger_agent" ]
    plutil -lint "$expected_trigger_agent"
    # it should have correct key/values in trigger agent
    defaults read "$expected_trigger_agent" Label | grep "^com.cybertk.launchd-oneshot.$expected_job.trigger$"
    defaults read "$expected_trigger_agent" Program | grep "^$SCRIPT_PATH$"
    defaults read "$expected_trigger_agent" ProgramArguments | wc -l | grep "4"
    defaults read "$expected_trigger_agent" ProgramArguments | grep "$SCRIPT_PATH"
    defaults read "$expected_trigger_agent" ProgramArguments | grep "$expected_job.trigger"
    defaults read "$expected_trigger_agent" EnvironmentVariables | grep '"LAUNCHD_ONESHOT_JOB" = 1;'
    defaults read "$expected_trigger_agent" KeepAlive | grep "SuccessfulExit = 0;"
    defaults read "$expected_trigger_agent" RunAtLoad | grep "^1$"
    defaults read "$expected_trigger_agent" StandardErrorPath | grep "^$LOGS_DIR/$expected_job.log$"
    defaults read "$expected_trigger_agent" StandardOutPath | grep "^$LOGS_DIR/$expected_job.log$"
}
