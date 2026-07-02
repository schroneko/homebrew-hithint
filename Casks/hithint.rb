cask "hithint" do
  version "1.0.0"
  sha256 "46a70378ccf66a22a55236db57862f6d1fa463c0e75aa1247bd36f1593af08ed"

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
