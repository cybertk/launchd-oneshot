class LaunchdOneshot < Formula
  desc "Add a oneshot launchd jobs"
  homepage "https://github.com/cybertk/launchd-oneshot"
  url "https://github.com/cybertk/launchd-oneshot.git",
    :tag => "v0.0.2",
    :revision => "0ff1208011f0878a5af16b29fd3a3291fcebcad9"

  head "https://github.com/cybertk/launchd-oneshot.git"

  depends_on "coreutils"

  def install
    bin.install "launchd-oneshot"
  end

  test do
    assert_match /Usage/, shell_output("launchd-oneshot tests/job.sh")
  end
end
