class LaunchdOneshot < Formula
  desc "Add a oneshot launchd jobs"
  homepage "https://github.com/cybertk/launchd-oneshot"
  url "https://github.com/cybertk/launchd-oneshot.git",
    :tag => "v0.0.1",
    :revision => "c905bb15f59d19fb858569f6b0f9fa77e4201e19"

  head "https://github.com/cybertk/launchd-oneshot.git"

  depends_on "coreutils"

  def install
    bin.install "launchd-oneshot"
  end

  test do
    assert_match /Usage/, shell_output("launchd-oneshot tests/job.sh")
  end
end
