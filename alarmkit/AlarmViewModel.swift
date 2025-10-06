import ActivityKit
import AlarmKit
import SwiftUI

@Observable class AlarmViewModel {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<CookingData>
    // UUIDをキー、(Alarm, LocalizedStringResource)のタプルを値とする辞書
    typealias AlarmsMap = [UUID: (Alarm, LocalizedStringResource)]

    // アプリ内で管理している前アラームを格納する辞書
    @MainActor var alarmsMap = AlarmsMap()
    // シングルトンのAlarmManagerインスタンス
    // alarmManager自体はシングルトンのため監視する必要がないから、監視対象から除外
    @ObservationIgnored private let alarmManager = AlarmManager.shared

    @MainActor var hasUpcomingAlerts: Bool {
        !alarmsMap.isEmpty
    }

    func scheduleAlertOnly() {

        let alertContent = AlarmPresentation.Alert(
            title: "Wake Up",
            stopButton: .stopButton
        )

        let attributes = AlarmAttributes<CookingData>(
            presentation: AlarmPresentation(alert: alertContent),
            tintColor: Color.accentColor
        )

        let sound = AlertConfiguration.AlertSound.named("sample.caf")

        let alarmConfiguration = AlarmConfiguration.timer(
            duration: 60,
            attributes: attributes,
            sound: sound
        )

        scheduleAlarm(id: UUID(), label: "Wake Up", alarmConfiguration: alarmConfiguration)
    }

    func scheduleCustomButtonAlert() {
        let alertContent = AlarmPresentation.Alert(
            title: "Wake Up",  // アラートのタイトル
            stopButton: .stopButton,  // 停止ボタン
            secondaryButton: .openAppButton,  // セカンダリボタン
            secondaryButtonBehavior: .custom)  // ボタンの動作をカスタム実装
        // .default → ボタンを押すと自動的にアラートが閉じる
        // .custom → ボタンを押した時の動作を自分で実装する (secondaryIntentで指定)

        // <CookingData> はLive Activityの属性データの型
        let attributes = AlarmAttributes<CookingData>(
            presentation: AlarmPresentation(alert: alertContent),  // アラート設定
            tintColor: Color.accentColor)  // アラートのテーマカラー

        let id = UUID()  // アラームの一意な識別子
        let alarmConfiguration = AlarmConfiguration(
            schedule: .oneMinsFromNow,  // いつ鳴らすか
            attributes: attributes,  // 表示設定
            stopIntent: StopIntent(alarmID: id.uuidString),  // 停止ボタンの処理
            secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString))  // セカンダリボタンの処理

        scheduleAlarm(id: id, label: "Wake Up", alarmConfiguration: alarmConfiguration)
    }

    private func scheduleAlarm(
        id: UUID, label: LocalizedStringResource, alarmConfiguration: AlarmConfiguration
    ) {
        Task {
            do {
                guard await requestAuthorization() else {
                    print("Not authorized to schedule alarms.")
                    return
                }
                let alarm = try await alarmManager.schedule(
                    id: id, configuration: alarmConfiguration)
                await MainActor.run {
                    alarmsMap[id] = (alarm, label)
                }
            } catch {
                print("Error encountered when scheduling alarm: \(error)")
            }
        }
    }

    func unscheduleAlarm(with alarmID: UUID) {
        try? alarmManager.cancel(id: alarmID)
        Task { @MainActor in
            alarmsMap[alarmID] = nil
        }
    }
}

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }

    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }

    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }

    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }

    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
    }
}
