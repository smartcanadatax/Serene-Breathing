import SwiftUI

struct HealthPermissionView: View {
    let onAllow: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 32)

                // Title
                Text("Connect to Apple Health")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 16)

                // Subtitle
                Text("Serene Breathing can save your meditation sessions as Mindful Minutes in Apple Health — so your wellness data stays in one place.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)

                Spacer().frame(height: 40)

                // Benefits
                VStack(spacing: 14) {
                    HealthBenefitRow(icon: "brain.head.profile", text: "Meditation sessions saved automatically")
                    HealthBenefitRow(icon: "clock.fill",         text: "Mindful minutes tracked over time")
                    HealthBenefitRow(icon: "lock.fill",          text: "Data stays on your device — write only")
                }
                .padding(.horizontal, 36)

                Spacer().frame(height: 48)

                // Allow button
                Button(action: onAllow) {
                    Text("Allow Health Access")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.31, green: 0.44, blue: 0.77))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                }
                .padding(.horizontal, 32)

                // Skip button
                Button(action: onSkip) {
                    Text("Not Now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.60))
                        .padding(.vertical, 14)
                }

                Spacer().frame(height: 16)
            }
        }
    }
}

private struct HealthBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
    }
}
