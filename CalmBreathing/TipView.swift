import StoreKit
import SwiftUI

// MARK: - Tip Store
@MainActor
class TipStore: ObservableObject {

    static let productIDs = [
        "com.serenebreathing.tip.1",
        "com.serenebreathing.tip.2",
        "com.serenebreathing.tip.5"
    ]

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var didTip = false

    init() { Task { await loadProducts() } }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("TipStore load error: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            if case .success = result {
                didTip = true
                Self.markShown()
            }
        } catch {
            print("TipStore purchase error: \(error)")
        }
    }

    // Show at most once per week
    static var shouldShow: Bool {
        guard let last = UserDefaults.standard.object(forKey: "lastTipPrompt") as? Date else { return true }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0 >= 7
    }

    static func markShown() {
        UserDefaults.standard.set(Date(), forKey: "lastTipPrompt")
    }
}

// MARK: - Tip Card View
struct TipCardView: View {
    @Binding var isPresented: Bool
    @StateObject private var store = TipStore()

    var body: some View {
        ZStack {
            CalmBackground()

            VStack(spacing: 0) {
                // Dismiss handle
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 4)
                    .padding(.top, 16)

                Spacer()

                if store.didTip {
                    thankYouView
                } else {
                    tipView
                }

                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Tip View
    private var tipView: some View {
        VStack(spacing: 28) {

            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 100, height: 100)
                Text("🙏")
                    .font(.system(size: 50))
            }

            // Headline
            VStack(spacing: 10) {
                Text("Did this bring you calm?")
                    .font(.system(size: 26, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Serene Breathing is completely free — no ads, no subscriptions, no pressure.\n\nIf a session helped you today, a small tip keeps this app free for everyone.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            // Tip buttons
            HStack(spacing: 12) {
                if store.products.isEmpty {
                    // Shown while StoreKit loads or in development
                    tipButton(label: "$1", isLoading: false, action: {})
                    tipButton(label: "$2", isLoading: false, action: {})
                    tipButton(label: "$5", isLoading: false, action: {})
                } else {
                    ForEach(store.products, id: \.id) { product in
                        tipButton(label: product.displayPrice, isLoading: store.isPurchasing) {
                            Task { await store.purchase(product) }
                        }
                    }
                }
            }

            // No thanks
            Button {
                TipStore.markShown()
                isPresented = false
            } label: {
                Text("No thanks — continue")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Thank You View
    private var thankYouView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.calmAccent.opacity(0.15))
                    .frame(width: 100, height: 100)
                Text("💙")
                    .font(.system(size: 52))
            }

            Text("Thank You")
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundColor(.white)

            Text("Your generosity means the world. It helps keep this app free, calm, and ad-free for everyone who needs it.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Button {
                isPresented = false
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.calmDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color.calmAccent).shadow(color: .calmAccent.opacity(0.35), radius: 12))
            }
        }
    }

    // MARK: - Tip Button
    private func tipButton(label: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                if isLoading {
                    ProgressView()
                        .tint(Color.calmDeep)
                        .frame(height: 24)
                } else {
                    Text(label)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.calmDeep)
                }
                Text("tip")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.calmDeep.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.calmAccent)
                    .shadow(color: Color.calmAccent.opacity(0.40), radius: 10, y: 4)
            )
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }
}
