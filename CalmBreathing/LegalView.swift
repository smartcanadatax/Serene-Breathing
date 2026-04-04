import SwiftUI

// MARK: - Legal View (Disclaimer · Privacy Policy · Terms & Conditions)
struct LegalView: View {
    enum Section: String, CaseIterable {
        case disclaimer  = "Disclaimer"
        case privacy     = "Privacy Policy"
        case terms       = "Terms & Conditions"
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Section = .disclaimer

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Text("Legal")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

                // Segment picker
                Picker("", selection: $selected) {
                    ForEach(Section.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    legalText(for: selected)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Content
    @ViewBuilder
    private func legalText(for section: Section) -> some View {
        switch section {
        case .disclaimer:  disclaimerContent
        case .privacy:     privacyContent
        case .terms:       termsContent
        }
    }

    // MARK: - Disclaimer
    private var disclaimerContent: some View {
        LegalCard {
            LegalHeading("Medical Disclaimer")
            LegalBody("Serene Breathing is designed for general wellness and relaxation purposes only. It is not a medical application and is not intended to diagnose, treat, cure, or prevent any medical condition.")

            LegalHeading("Not a Substitute for Professional Advice")
            LegalBody("The content provided in this app — including guided meditations, breathing exercises, ambient sounds, mood tracking, sleep journaling, and challenge features — does not constitute medical, psychological, or therapeutic advice. Always consult a qualified healthcare professional before beginning any new wellness practice, especially if you have a physical or mental health condition.")

            LegalHeading("Mood & Sleep Trackers")
            LegalBody("The Mood Journal and Sleep Journal are personal reflection tools only. They are not diagnostic instruments, clinical assessments, or substitutes for professional mental health or sleep medicine evaluation. Data is stored locally on your device and is never shared. If you are experiencing persistent low mood, anxiety, sleep disorders, or any mental health concerns, please seek advice from a qualified healthcare professional.")

            LegalHeading("Use at Your Own Risk")
            LegalBody("You assume full responsibility for your use of this app. The developers of Serene Breathing shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of or inability to use the app.")

            LegalHeading("Emergency Situations")
            LegalBody("If you are experiencing a medical or mental health emergency, please contact emergency services (911) or a crisis helpline immediately. This app is not equipped to handle emergencies.")
        }
    }

    // MARK: - Privacy Policy
    private var privacyContent: some View {
        LegalCard {
            LegalBody("Last updated: March 2026")

            LegalHeading("Information We Collect")
            LegalBody("Serene Breathing does not collect, store, or transmit any personal data. All preferences and settings are stored locally on your device using Apple's standard UserDefaults and are never shared with third parties.")

            LegalHeading("Notifications")
            LegalBody("If you enable daily reminders, notification permissions are requested through Apple's standard framework. Notification data remains entirely on your device and is not accessible to us.")

            LegalHeading("Third-Party Services")
            LegalBody("This app does not integrate with any third-party analytics, advertising, or tracking services. No data is shared with or sold to third parties.")

            LegalHeading("Children's Privacy")
            LegalBody("This app does not knowingly collect information from children under the age of 13. If you believe a child has provided personal information, please contact us so we can take appropriate action.")

            LegalHeading("Changes to This Policy")
            LegalBody("We may update this Privacy Policy from time to time. Any changes will be reflected within the app. Continued use of the app after changes constitutes your acceptance of the updated policy.")

            LegalHeading("Contact")
            LegalBody("If you have questions about this Privacy Policy, please contact us through the App Store support link.")
        }
    }

    // MARK: - Terms & Conditions
    private var termsContent: some View {
        LegalCard {
            LegalBody("Last updated: March 2026")

            LegalHeading("Acceptance of Terms")
            LegalBody("By downloading or using Serene Breathing, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.")

            LegalHeading("License")
            LegalBody("We grant you a limited, non-exclusive, non-transferable, revocable license to use Serene Breathing for personal, non-commercial purposes on Apple devices you own or control, subject to these Terms.")

            LegalHeading("Permitted Use")
            LegalBody("You may use the app solely for lawful, personal wellness purposes. You may not copy, modify, distribute, sell, or reverse engineer any part of the app.")

            LegalHeading("Intellectual Property")
            LegalBody("All content within Serene Breathing — including but not limited to design, graphics, text, and audio — is the property of the developer or used under applicable licenses. Unauthorised reproduction is prohibited.")

            LegalHeading("Music & Audio Credits")
            LegalBody("Third-party music used in this app is licensed under Creative Commons and other applicable licenses. Full credits are listed in the Music Credits section of Settings.\n\n• \"Close Sea Waves Loop\" by Mixkit · Mixkit Free License\n• \"Escape Forest\" by FSM Team · CC BY 4.0\n• \"Ambient Music Nature\" by Alex Productions · CC BY 3.0\n• \"Ohm\" by Jason Shaw · audionautix.com · CC BY 4.0\n• \"Meditate with Nature\" by ChilledMusic · CC BY 4.0\n• \"Rain Sleep Meditation\" by Holizna · CC0 1.0 Public Domain\n• \"Peaceful Mind\" by Astron · CC BY 4.0\n• \"Spiritual Yoga\" by ChilledMusic · CC BY 4.0\n• \"Zen Water Healing\" by ChilledMusic · CC BY 4.0\n• \"Downpour\" by Keys of Moon · CC BY 4.0")

            LegalHeading("Disclaimer of Warranties")
            LegalBody("The app is provided \"as is\" without warranties of any kind. We do not guarantee that the app will be error-free, uninterrupted, or meet your specific requirements.")

            LegalHeading("Limitation of Liability")
            LegalBody("To the maximum extent permitted by law, the developers of Serene Breathing shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app.")

            LegalHeading("Governing Law")
            LegalBody("These Terms shall be governed by and construed in accordance with the laws of Ontario, Canada, without regard to its conflict of law provisions.")

            LegalHeading("Changes to Terms")
            LegalBody("We reserve the right to modify these Terms at any time. Continued use of the app after changes constitutes your acceptance of the revised Terms.")
        }
    }
}

// MARK: - First-Launch Terms Gate
struct TermsGateView: View {
    @AppStorage("hasAgreedToTerms") private var hasAgreedToTerms = false
    @State private var showFullTerms = false

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.calmAccent)
                }

                // Title
                VStack(spacing: 8) {
                    Text("Terms & Privacy")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Before you begin, please review how we protect your data and the terms of use.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.80))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 24)

                // Key points
                VStack(spacing: 14) {
                    termRow(icon: "hand.raised.fill",
                            title: "No data collected",
                            body: "All your data stays on your device. We collect nothing.")
                    termRow(icon: "cross.circle.fill",
                            title: "Not medical advice",
                            body: "Breathing exercises and meditations are for relaxation only.")
                    termRow(icon: "lock.shield.fill",
                            title: "Your privacy first",
                            body: "No analytics, no ads, no third-party tracking — ever.")
                }
                .padding(.horizontal, 8)
                .padding(.top, 28)

                // Full T&C link
                Button { showFullTerms = true } label: {
                    Text("Read full Terms & Privacy Policy")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.calmAccent)
                        .underline()
                }
                .padding(.top, 24)

                Spacer()

                // Agreement note
                Text("By tapping \"I Agree & Continue\" you confirm that you have read and agree to the Terms & Conditions and Privacy Policy.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                // CTA
                Button {
                    hasAgreedToTerms = true
                } label: {
                    Text("I Agree & Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.calmDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showFullTerms) {
            NavigationStack { LegalView() }
        }
    }

    private func termRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.calmAccent)
                .frame(width: 26)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(body)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Reusable Legal Layout Components
private struct LegalCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
        .padding(.top, 4)
    }
}

private struct LegalHeading: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top, 6)
    }
}

private struct LegalBody: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.white.opacity(0.80))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}
