class LaunchdOneshot < Formula
  desc "Add a oneshot launchd jobs"
  homepage "https://github.com/cybertk/launchd-oneshot"
  url "https://github.com/cybertk/launchd-oneshot.git",
    :tag => "v0.0.3",
    :revision => "8ec5af8f04d309139ac4d2618031701434580a1a"

  head "https://github.com/cybertk/launchd-oneshot.git"

  depends_on "coreutils"

  def install
    bin.install "launchd-oneshot"
  end

  test do
    assert_match /Usage/, shell_output("launchd-oneshot tests/job.sh")
  end
end
