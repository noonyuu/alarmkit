1. ユーザーがボタンをタップ
   ↓
2. [AlarmView.swift:15 or 23] ボタンアクション
   viewModel.scheduleAlertOnly() または
   viewModel.scheduleCustomButtonAlert()
   ↓
3. [AlarmViewModel.swift:34-38 or 55-59] AlarmConfiguration 作成
   .timer(duration: 60, ...) → タイマー形式
   または
   AlarmConfiguration(schedule: .oneMinsFromNow, ...) → スケジュール形式
   ↓
4. [AlarmViewModel.swift:73-74] AlarmManager でスケジュール
   let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
   ↓
5. [AlarmViewModel.swift:76] ViewModel の辞書に保存
   alarmsMap[id] = (alarm, label)
   ↓
6. [AlarmView.swift:33] ViewModel から取得
   alarmList(alarms: Array(viewModel.alarmsMap.values))
   ↓
7. [AlarmView.swift:40] AlarmCell にデータを渡す
   AlarmCell(alarm: alarm, label: label)
   ↓
8. [AlarmCell.swift:11-19] 表示の分岐
   if let alertingTime = alarm.alertingTime {
   // スケジュール形式なら時刻を表示
   } else if let countdown = alarm.countdownDuration?.preAlert {
   // タイマー形式ならカウントダウンを表示
   }

パターン 1: .scheduleAlertOnly() で作成したアラーム
AlarmConfiguration.timer(duration: 60, ...)
・alarm.schedule は nil (AlarmConfiguration で schedule を指定していないため)
・alarm.alertingTime も nil (schedule がないため)
・alarm.countdownDuration に値がある
→ else if ブロックが実行され、カウントダウン表示
パターン 2: .scheduleCustomButtonAlert() で作成したアラーム
AlarmConfiguration(schedule: .oneMinsFromNow, ...)
・alarm.schedule = .relative(...)
・alarm.alertingTime に計算結果が入る
→ if ブロックが実行され、時刻表示
