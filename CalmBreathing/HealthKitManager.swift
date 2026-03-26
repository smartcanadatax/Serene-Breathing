import HealthKit
import Foundation

// MARK: - HealthKit Manager
/// Saves mindfulness sessions to Apple Health after each completed meditation.
class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private var mindfulType: HKCategoryType {
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    }

    // MARK: - Availability
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Request Permission
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else { completion(false); return }
        store.requestAuthorization(toShare: [mindfulType], read: []) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Save Session
    func saveMindfulSession(startDate: Date, endDate: Date) {
        guard isAvailable else { return }
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        store.save(sample) { _, error in
            if let error { print("HealthKit save error: \(error)") }
        }
    }
}
