class LaunchdOneshot < Formula
  desc "Add a oneshot launchd jobs"
  homepage "https://github.com/cybertk/launchd-oneshot"
  url "https://github.com/cybertk/launchd-oneshot.git",
    :tag => "v0.1.0-beta.1",
    :revision => "a705e31d2d27ac3e93684ab99c2073fb34e46412"

  head "https://github.com/cybertk/launchd-oneshot.git"

  depends_on "coreutils"

  def install
    bin.install "launchd-oneshot"
  end

  test do
    assert_match /Usage/, shell_output("launchd-oneshot tests/job.sh")
  end
end
