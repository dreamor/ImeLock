//
//  AboutView.swift
//  ImeLock
//

import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)

            Text("ImeLock")
                .font(.system(size: 20, weight: .bold))

            Text("v\(appVersion)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text(NSLocalizedString("about.description", comment: "About: app description"))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(NSLocalizedString("about.author", comment: "About: author label"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Link("Scott", destination: URL(string: "https://github.com/dreamor/ImeLock")!)
                        .font(.system(size: 12))
                }

                HStack(spacing: 4) {
                    Text(NSLocalizedString("about.acknowledgements", comment: "About: acknowledgements label"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Link("SwitchKey", destination: URL(string: "https://github.com/itsuhane/SwitchKey")!)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(30)
        .frame(width: 280)
    }
}
