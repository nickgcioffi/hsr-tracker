import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ResourceImageView: View {
    let resourcePath: String?
    let size: CGFloat
    let fallbackSystemImage: String

    var body: some View {
        Group {
            if let image = loadImage() {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSystemImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityHidden(true)
    }

    private func loadImage() -> Image? {
        guard let resourcePath,
              let url = GameDataService.shared.imageURL(for: resourcePath) else {
            return nil
        }

#if os(iOS)
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        return Image(uiImage: image)
#elseif os(macOS)
        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        return Image(nsImage: image)
#else
        return nil
#endif
    }
}
