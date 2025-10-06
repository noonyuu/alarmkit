import AlarmKit

func requestAuthorization() async -> Bool {
    switch AlarmManager.shared.authorizationState {
    case .notDetermined:
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            print("Error occurred while requesting authorization: \(error)")
            return false
        }
    case .denied:
    return false
    case .authorized:
        return true
    @unknown default:
        return false
    }
}
