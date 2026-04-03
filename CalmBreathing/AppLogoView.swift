import SwiftUI

// MARK: - App Logo View
// Uses the real AppLogo PNG asset. Usage: AppLogoView(size: 40)
struct AppLogoView: View {
    var size: CGFloat = 40

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        AppLogoView(size: 40)
        AppLogoView(size: 64)
        AppLogoView(size: 120)
    }
    .padding(40)
    .background(Color(red: 0.08, green: 0.12, blue: 0.28))
}
