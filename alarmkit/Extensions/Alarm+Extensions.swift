/*
Alarm 型の拡張
アラームが実際になる時刻を計算する
*/

import AlarmKit

extension Alarm {
    var alertingTime: Date? {
        // スケジュールが存在しない場合は nil を返す
        guard let schedule else { return nil }

        switch schedule {
        // 固定スケジュール
        // 指定された日時をそのまま返す
        case .fixed(let date):
            return date
        // 相対スケジュール
        case .relative(let relative):
            // 今日の年月日を取得
            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: Date())
            // 時刻部分だけを置き換え
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            // 今日の指定時刻として返す
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
        }
    }
}
