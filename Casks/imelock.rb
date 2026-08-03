cask "imelock" do
  version "1.1.1"
  # SHA256 is auto-updated in the homebrew-tap repo after each release -- do not edit manually
  sha256 "7324d527a9a11a77c7e6cfd9a1fc06c047ab98e5e649c7e6b78d573f3fa024d0"

  url "https://github.com/dreamor/ImeLock/releases/download/v#{version}/ImeLock-#{version}.zip"
  name "ImeLock"
  desc "macOS input method locker - prevent accidental switching across apps"
  homepage "https://github.com/dreamor/ImeLock"

  depends_on macos: ">= :sonoma"

  app "ImeLock.app"

  zap trash: [
    "~/Library/Caches/com.scottwang.ImeLock",
    "~/Library/Preferences/com.scottwang.ImeLock.plist",
  ]

  caveats <<~EOS
    ImeLock is not code-signed. On first launch:
      1. Right-click ImeLock.app and select "Open"
      2. Click "Open" in the Gatekeeper dialog

    After the first launch, it will open normally.
  EOS
end