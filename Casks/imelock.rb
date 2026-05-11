cask "imelock" do
  version "1.0.0"
  sha256 "PLACEHOLDER_UPDATE_ON_RELEASE"

  url "https://github.com/dreamor/ImeLock/releases/download/v#{version}/ImeLock-#{version}.zip"
  name "ImeLock"
  desc "macOS input method locker - lock input method per app"
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