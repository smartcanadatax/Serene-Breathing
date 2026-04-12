import SwiftUI
import StoreKit

// MARK: - Paywall View
struct PaywallView: View {
    @EnvironmentObject var premium: PremiumStore
    @Binding var isPresented: Bool

    @State private var selectedProduct: Product?
    @State private var isRestoring = false

    private var monthlyProduct: Product? {
        premium.products.first { $0.id == PremiumStore.monthlyID }
    }
    private var yearlyProduct: Product? {
        premium.products.first { $0.id == PremiumStore.yearlyID }
    }

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {

                // Close button
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {

                        // Header
                        VStack(spacing: 10) {
                            MeditationOrbView()
                                .frame(width: 86, height: 86)
                                .shadow(color: .calmAccent.opacity(0.3), radius: 12)

                            Text("Serene Premium")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Everything you need for a calmer mind")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 4)

                        // Feature list
                        VStack(spacing: 13) {
                            featureRow(icon: "moon.stars.fill",      text: "Sleep Meditation")
                            featureRow(icon: "figure.mind.and.body", text: "Body Scan")
                            featureRow(icon: "book.fill",            text: "Sleep Stories")
                            featureRow(icon: "sparkles",             text: "Personalized Meditation")
                            featureRow(icon: "music.note",           text: "Ambient Music — Focus · Sleep · Creativity")
                            featureRow(icon: "waveform",             text: "All 50+ meditation & nature sounds")
                            featureRow(icon: "bell.fill",            text: "Silent Meditation with interval bells")
                            featureRow(icon: "timer",                text: "Full meditation timer — up to 60 min")
                            featureRow(icon: "moon.fill",            text: "Sleep Journal & unlimited mood history")
                            featureRow(icon: "brain.head.profile",   text: "Mood Pattern Coach")
                            featureRow(icon: "zzz",                  text: "Sleep Pattern Coach")
                            featureRow(icon: "message.fill",         text: "AI Coach — unlimited conversations")
                        }
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.10)))

                        // Plan selector
                        VStack(spacing: 10) {
                            if let yearly = yearlyProduct {
                                planButton(
                                    title:    "Yearly",
                                    price:    yearly.displayPrice + "/year",
                                    subtitle: "Best value — save over 35%",
                                    badge:    "BEST VALUE",
                                    isSelected: selectedProduct?.id == yearly.id
                                ) { selectedProduct = yearly }
                            }
                            if let monthly = monthlyProduct {
                                planButton(
                                    title:    "Monthly",
                                    price:    monthly.displayPrice + "/month",
                                    subtitle: "Billed monthly, cancel anytime",
                                    badge:    nil,
                                    isSelected: selectedProduct?.id == monthly.id
                                ) { selectedProduct = monthly }
                            }
                            if premium.products.isEmpty {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }

                        // Error message
                        if let err = premium.errorMessage {
                            Text(err)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }

                        // Subscribe button
                        Button {
                            Task {
                                guard let product = selectedProduct else { return }
                                await premium.purchase(product)
                                if premium.isPremium { isPresented = false }
                            }
                        } label: {
                            Group {
                                if premium.isPurchasing {
                                    ProgressView().tint(.calmDeep)
                                } else {
                                    Text("Start Premium")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.36, green: 0.22, blue: 0.60))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 14)
                            )
                        }
                        .disabled(selectedProduct == nil || premium.isPurchasing)
                        .opacity(selectedProduct == nil ? 0.5 : 1)

                        // Restore
                        Button {
                            isRestoring = true
                            Task {
                                await premium.restorePurchases()
                                isRestoring = false
                                if premium.isPremium { isPresented = false }
                            }
                        } label: {
                            Text(isRestoring ? "Restoring…" : "Restore Purchases")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.60))
                        }

                        // Legal links (required by App Store Guideline 3.1.2c)
                        HStack(spacing: 16) {
                            Link("Privacy Policy", destination: URL(string: "https://serenebreathing.online/#privacy")!)
                            Text("·").foregroundColor(.white.opacity(0.30))
                            Link("Terms of Use", destination: URL(string: "https://serenebreathing.online/#terms")!)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.60))

                        // Legal
                        Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple ID settings.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            // Auto-select yearly plan
            selectedProduct = premium.products.first { $0.id == PremiumStore.yearlyID }
                           ?? premium.products.first
        }
        .onChange(of: premium.products) { _, _ in
            if selectedProduct == nil {
                selectedProduct = premium.products.first { $0.id == PremiumStore.yearlyID }
                               ?? premium.products.first
            }
        }
    }

    // MARK: - Feature Row
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.calmAccent)
        }
    }

    // MARK: - Plan Button
    private func planButton(title: String, price: String, subtitle: String, badge: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.calmDeep)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.calmAccent))
                        }
                    }
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.60))
                }
                Spacer()
                Text(price)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.18 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.calmAccent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
    }
}
