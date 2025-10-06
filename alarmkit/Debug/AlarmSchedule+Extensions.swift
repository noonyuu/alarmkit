/*
Alarm.Schedule 型の拡張
現在時刻から1分後のアラームスケジュールを生成する
*/

import AlarmKit

extension Alarm.Schedule {
    static var oneMinsFromNow: Self {
        // 現在時刻から1分後のアラームスケジュールを生成する
        let oneMinsFromNow = Date().addingTimeInterval(60)
        // 1分後の日付から時間と分を抽出
        let time = Alarm.Schedule.Relative.Time(
            hour: Calendar.current.component(.hour, from: oneMinsFromNow),
            minute: Calendar.current.component(.minute, from: oneMinsFromNow)
        )
        // 相対スケジュールを返す(時刻のみを指定)
        return .relative(.init(time: time))
    }
}
