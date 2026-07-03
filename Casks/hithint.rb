cask "hithint" do
  version "1.1.0"
  sha256 "1b6a4cbdc52312bd0feb5fe77c4d0e19093640be626f8b54c0b32b1b3a282ffe"

  url "https://github.com/schroneko/homebrew-hithint/releases/download/v#{version}/HitHint-#{version}.zip"
  name "HitHint"
  desc "Keyboard hint clicking and scrolling for macOS"
  homepage "https://github.com/schroneko/homebrew-hithint"

  app "HitHint.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "/Applications/HitHint.app"],
                   sudo: false
  end

  caveats <<~EOS
    HitHint requires the macOS Accessibility permission.
    Grant it in System Settings > Privacy & Security > Accessibility.
  EOS

  uninstall quit: "com.schroneko.HitHint"

  zap trash: [
    "~/Library/Application Support/HitHint",
    "~/Library/Preferences/com.schroneko.HitHint.plist",
  ]
end
