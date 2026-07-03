cask "hithint" do
  version "1.2.0"
  sha256 "3304680fe1888d72aa49d65023ee4bfb31fb802310caa2c1ef5c15f7a0d758f1"

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
