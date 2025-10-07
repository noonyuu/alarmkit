# AlarmKit と Live Activity の仕組み(推測含む)

## 概要

AlarmKit は `alarmManager.schedule()` を呼ぶだけで、自動的に Live Activity を表示・管理する仕組みになっている

## 重要なポイント

### AlarmAttributes は ActivityAttributes を継承

```swift
// AlarmKit.swiftinterface:531
public struct AlarmAttributes<Metadata> : ActivityAttributes, Sendable where Metadata : AlarmMetadata {
    public typealias ContentState = AlarmPresentationState

    public var presentation: AlarmPresentation
    public var metadata: Metadata?
    public var tintColor: Color
}
```

この継承により、ActivityKit のシステムが AlarmAttributes を Live Activity として認識できる

### AlarmManager.schedule() のシグネチャ

```swift
// AlarmKit.swiftinterface:810
public func schedule<Metadata>(
    id: Alarm.ID,
    configuration: AlarmManager.AlarmConfiguration<Metadata>
) async throws -> Alarm where Metadata : AlarmMetadata
```

このメソッドは `AlarmConfiguration` を受け取り、その中に `AlarmAttributes` が含まれている

### AlarmConfiguration の構造

```swift
// AlarmKit.swiftinterface:750-761
public struct AlarmConfiguration<Metadata> where Metadata : AlarmMetadata {
    public init(
        countdownDuration: Alarm.CountdownDuration? = nil,
        schedule: Alarm.Schedule? = nil,
        attributes: AlarmAttributes<Metadata>,  // Live Activity の設定
        stopIntent: (any LiveActivityIntent)? = nil,
        secondaryIntent: (any LiveActivityIntent)? = nil,
        sound: AlertConfiguration.AlertSound = .default
    )
}
```

## データの流れ

```
1. AlarmAttributes を作成
   ↓
2. AlarmConfiguration に attributes を渡す
   ↓
3. alarmManager.schedule(id: id, configuration: alarmConfiguration)
   ↓
4. AlarmKit 内部で Live Activity を起動（内部実装）
   ↓
5. システムが AlarmAttributes<CookingData> にマッチする
   ActivityConfiguration を探す
   ↓
6. Widget Extension (AlarmLiveActivity) が起動
   ↓
7. ロック画面・Dynamic Island に表示
```

## 実装例

### 1. AlarmAttributes の作成

```swift
let alertContent = AlarmPresentation.Alert(
    title: "Wake Up",
    stopButton: .stopButton,
    secondaryButton: .openAppButton,
    secondaryButtonBehavior: .custom
)

let attributes = AlarmAttributes<CookingData>(
    presentation: AlarmPresentation(alert: alertContent),
    metadata: CookingData(method: .stove),
    tintColor: Color.accentColor
)
```

### 2. AlarmConfiguration の作成

```swift
let alarmConfiguration = AlarmConfiguration(
    schedule: .oneMinsFromNow,
    attributes: attributes,
    stopIntent: StopIntent(alarmID: id.uuidString),
    secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString)
)
```

### 3. スケジュール実行

```swift
let alarm = try await alarmManager.schedule(
    id: id,
    configuration: alarmConfiguration
)
// この時点で Live Activity が自動的に表示される
```

### 4. Widget Extension での定義

```swift
// AlarmLiveActivity.swift
struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // AlarmAttributes<CookingData> と型が一致
        ActivityConfiguration(for: AlarmAttributes<CookingData>.self) { context in
            // ロック画面の UI
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // Dynamic Island の UI
            DynamicIsland { ... }
        }
    }
}
```

## 型マッチングの仕組み

```
AlarmManager.schedule()
  ├─ AlarmConfiguration<CookingData>
  │   └─ attributes: AlarmAttributes<CookingData>
  │
  └─ システムが Widget Extension を検索
      └─ ActivityConfiguration(for: AlarmAttributes<CookingData>.self)
          └─ 型が一致 → AlarmLiveActivity を起動
```

## やること

### 必要なこと

1. `AlarmAttributes` を設定（presentation, metadata, tintColor）
2. `AlarmConfiguration` を作成
3. `alarmManager.schedule()` を呼ぶ
4. Widget Extension で `ActivityConfiguration(for: AlarmAttributes<Metadata>.self)` を定義

### 不要なこと

1. `Activity.request()` を手動で呼ぶ
2. Live Activity の起動・停止を管理する
3. ActivityKit を直接扱う

## AlarmAttributes vs ActivityAttributes

### ActivityAttributes（標準の Live Activity）

```swift
// 手動で管理する場合
let attributes = MyAttributes(...)
let content = ActivityContent(state: MyState(), staleDate: nil)

let activity = try Activity<MyAttributes>.request(
    attributes: attributes,
    content: content
)
```

### AlarmAttributes（AlarmKit の場合）

```swift
// AlarmKit が自動管理
let attributes = AlarmAttributes<CookingData>(...)
let configuration = AlarmConfiguration(attributes: attributes, ...)

try await alarmManager.schedule(id: id, configuration: configuration)
// Activity.request() は呼ばなくて良い
```

## まとめ

AlarmKit は内部実装によって以下を自動化している(はず)

1. **Live Activity の起動** - `Activity.request()` の呼び出し
2. **状態の更新** - アラームの状態変化に応じた UI 更新
3. **Live Activity の終了** - アラーム停止時の終了処理

## 参考資料

- [AlarmKit Documentation](https://developer.apple.com/documentation/AlarmKit)
- [Scheduling an alarm with AlarmKit](https://developer.apple.com/documentation/AlarmKit/scheduling-an-alarm-with-alarmkit)
- [WWDC 2025 Session 230](https://developer.apple.com/videos/play/wwdc2025/230/)
