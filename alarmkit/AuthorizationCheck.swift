import AlarmKit

func authorizationCheck() async -> Bool {
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
        return false
    @unknown default:
        return false
    }
}
