#!/usr/bin/env bats

fixtures() {
    PATH="$BATS_TEST_DIRNAME/..:$PATH"
    FIXTURE_DIR="$BATS_TEST_DIRNAME/fixtures"
    SCRIPT_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/launchd-oneshot"

    JOBS_DIR=/usr/local/var/launchd-oneshot/jobs
    LOGS_DIR=/usr/local/var/log/launchd-oneshot

    PlistBuddy="/usr/libexec/PlistBuddy"
}

setup() {
    echo pass
}

teardown() {
    for plist in /Library/Launch{Agents,Daemons}/com.cybertk.launchd-oneshot.*; do
        launchctl unload "$plist"
        launchctl remove "$plist"
        sudo launchctl unload "$plist"
        sudo launchctl remove "$(basename "${plist%%.plist}")"
        sudo rm "$plist"
    done

    #sudo rm /Library/Launch{Agents,Daemons}/com.cybertk.launchd-oneshot.*.plist

    sudo rm -f /tmp/launchd-oneshot*
    sudo rm -f /tmp/com.cybertk.launchd-oneshot*
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
    $PlistBuddy -c 'Print :Label' "$expected_agent" | grep "^com.cybertk.launchd-oneshot.$expected_job$"
    $PlistBuddy -c 'Print :ProgramArguments' "$expected_agent" | wc -l | grep "4"
    $PlistBuddy -c 'Print :ProgramArguments:0' "$expected_agent" | grep "^$SCRIPT_PATH$"
    $PlistBuddy -c 'Print :ProgramArguments:1' "$expected_agent" | grep "^$expected_job$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_JOB' "$expected_agent" | grep "^1$"
    $PlistBuddy -c 'Print :KeepAlive:SuccessfulExit' "$expected_agent" | grep "^false$"
    $PlistBuddy -c 'Print :RunAtLoad' "$expected_agent" | grep "^true$"
    $PlistBuddy -c 'Print :StandardOutPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
    $PlistBuddy -c 'Print :StandardErrorPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
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
    # it should run job by root
    [ -f "$expected_job_signature.by.root" ]
    # it should generating log of job
    [ -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should removed agent
    [ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should removed installed job
    [ ! -f "$JOBS_DIR/$expected_job" ]
}

@test "installing a valid job with --on-login" {
    expected_job=valid.job
    expected_job_id=com.cybertk.launchd-oneshot.valid.job
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
    $PlistBuddy -c 'Print :Label' "$expected_agent" | grep "^com.cybertk.launchd-oneshot.$expected_job$"
    $PlistBuddy -c 'Print :ProgramArguments' "$expected_agent" | wc -l | grep "4"
    $PlistBuddy -c 'Print :ProgramArguments:0' "$expected_agent" | grep "^$SCRIPT_PATH$"
    $PlistBuddy -c 'Print :ProgramArguments:1' "$expected_agent" | grep "^$expected_job$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_JOB' "$expected_agent" | grep "^1$"
    $PlistBuddy -c 'Print :KeepAlive:OtherJobEnabled:'"$expected_job_id.trigger" "$expected_agent" | grep "^true$"
    $PlistBuddy -c 'Print :RunAtLoad' "$expected_agent" | grep "^false$"
    $PlistBuddy -c 'Print :StandardOutPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
    $PlistBuddy -c 'Print :StandardErrorPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
    # it should installed corresponding trigger agent under /Library/LaunchAgents/
    [ -f "$expected_trigger_agent" ]
    plutil -lint "$expected_trigger_agent"
    # it should have correct key/values in trigger agent
    $PlistBuddy -c 'Print :Label' "$expected_trigger_agent" | grep "^com.cybertk.launchd-oneshot.$expected_job.trigger$"
    $PlistBuddy -c 'Print :ProgramArguments' "$expected_trigger_agent" | wc -l | grep "4"
    $PlistBuddy -c 'Print :ProgramArguments:0' "$expected_trigger_agent" | grep "$SCRIPT_PATH"
    $PlistBuddy -c 'Print :ProgramArguments:1' "$expected_trigger_agent" | grep "^$expected_job.trigger$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_TRIGGER' "$expected_trigger_agent" | grep '^1$'
    $PlistBuddy -c 'Print :RunAtLoad' "$expected_trigger_agent" | grep "^true$"
}

@test "load a valid --on-login job" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login

    # when job is loaded
    sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    sleep 1

    # it should not run job
    [ ! -f "$expected_job_signature" ]
    # it should not generating log of job
    [ ! -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should not removed agent
    [ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should not removed installed job
    [ -f "$JOBS_DIR/$expected_job" ]
}

@test "load the trigger of a valid --on-login job" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login

    # when job is loaded
    launchctl load /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist
    sleep 1

    # it should created signal
    [ -f "/tmp/com.cybertk.launchd-oneshot.$expected_job.trigger.options" ]
}

@test "load the trigger of a valid --on-login job when job is loaded" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login

    # when job is loaded
    sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    launchctl load /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist
    sleep 1

    # it should run job
    [ -f "$expected_job_signature" ]
    # it should run job by current login user
    [ -f "$expected_job_signature.by.`id -un`" ]
    # it should generating log of job
    [ -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should removed agent
    [ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should removed trigger agent
    [ ! -f /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist ]
    # it should removed installed job
    [ ! -f "$JOBS_DIR/$expected_job" ]
    # it should removed trigger signal
    [ ! -f "/tmp/com.cybertk.launchd-oneshot.$expected_job.trigger.options" ]
}

@test "installing a valid job with --on-login-as-root" {
    expected_job=valid.job
    expected_job_id=com.cybertk.launchd-oneshot.valid.job
    expected_agent=/Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    expected_trigger_agent=/Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist

    run sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login-as-root
    # it should exit 0
    [ $status -eq 0 ]
    # it should installed job under $JOBS_DIR
    [ -f "$JOBS_DIR/$expected_job" ]
    # it should installed agent under /Library/LaunchDaemons/
    [ -f "$expected_agent" ]
    plutil -lint "$expected_agent"
    # it should have correct key/values in agent
    $PlistBuddy -c 'Print :Label' "$expected_agent" | grep "^com.cybertk.launchd-oneshot.$expected_job$"
    $PlistBuddy -c 'Print :ProgramArguments' "$expected_agent" | wc -l | grep "4"
    $PlistBuddy -c 'Print :ProgramArguments:0' "$expected_agent" | grep "^$SCRIPT_PATH$"
    $PlistBuddy -c 'Print :ProgramArguments:1' "$expected_agent" | grep "^$expected_job$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_JOB' "$expected_agent" | grep "^1$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_JOB_AS_ROOT' "$expected_agent" | grep "^1$"
    $PlistBuddy -c 'Print :KeepAlive:OtherJobEnabled:'"$expected_job_id.trigger" "$expected_agent" | grep "^true$"
    $PlistBuddy -c 'Print :RunAtLoad' "$expected_agent" | grep "^false$"
    $PlistBuddy -c 'Print :StandardOutPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
    $PlistBuddy -c 'Print :StandardErrorPath' "$expected_agent" | grep "^$LOGS_DIR/$expected_job.log$"
    # it should installed corresponding trigger agent under /Library/LaunchAgents/
    [ -f "$expected_trigger_agent" ]
    plutil -lint "$expected_trigger_agent"
    # it should have correct key/values in trigger agent
    $PlistBuddy -c 'Print :Label' "$expected_trigger_agent" | grep "^com.cybertk.launchd-oneshot.$expected_job.trigger$"
    $PlistBuddy -c 'Print :ProgramArguments' "$expected_trigger_agent" | wc -l | grep "4"
    $PlistBuddy -c 'Print :ProgramArguments:0' "$expected_trigger_agent" | grep "$SCRIPT_PATH"
    $PlistBuddy -c 'Print :ProgramArguments:1' "$expected_trigger_agent" | grep "^$expected_job.trigger$"
    $PlistBuddy -c 'Print :EnvironmentVariables:LAUNCHD_ONESHOT_RUN_TRIGGER' "$expected_trigger_agent" | grep '^1$'
    $PlistBuddy -c 'Print :RunAtLoad' "$expected_trigger_agent" | grep "^true$"
}

@test "load a valid --on-login-as-root job" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login-as-root

    # when job is loaded
    sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    sleep 1

    # it should not run job
    [ ! -f "$expected_job_signature" ]
    # it should not generating log of job
    [ ! -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should not removed agent
    [ -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should not removed installed job
    [ -f "$JOBS_DIR/$expected_job" ]
}

@test "load the trigger of a valid --on-login-as-root job" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login-as-root

    # when job is loaded
    launchctl load /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist
    sleep 1

    # it should created signal
    [ -f "/tmp/com.cybertk.launchd-oneshot.$expected_job.trigger.options" ]
}

@test "load the trigger of a valid --on-login-as-root job when job is loaded" {
    expected_job=valid.job
    expected_job_signature=/tmp/launchd-oneshot-fixtures.valid.job.signature
    sudo launchd-oneshot "$FIXTURE_DIR/$expected_job" --on-login-as-root

    # when job is loaded
    sudo launchctl load /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist
    launchctl load /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist
    sleep 1

    # it should run job
    [ -f "$expected_job_signature" ]
    # it should run job by root
    [ -f "$expected_job_signature.by.root" ]
    # it should generating log of job
    [ -f /usr/local/var/log/launchd-oneshot/$expected_job.log ]
    # it should removed agent
    [ ! -f /Library/LaunchDaemons/com.cybertk.launchd-oneshot.$expected_job.plist ]
    # it should removed trigger agent
    [ ! -f /Library/LaunchAgents/com.cybertk.launchd-oneshot.$expected_job.trigger.plist ]
    # it should removed installed job
    [ ! -f "$JOBS_DIR/$expected_job" ]
    # it should removed trigger signal
    [ ! -f "/tmp/com.cybertk.launchd-oneshot.$expected_job.trigger.options" ]
}
