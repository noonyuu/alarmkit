/*
  ロック画面やDynamic Islandに表示されるUI
*/

import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

// Widgetのメイン構造
struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // ActivityConfigurationでLive Activityの設定を定義
        // AlarmAttributes<CookingData>型のアラーム情報を受け取る(CookingDataのファイルのターゲットにalarmkitActivityが追加されてる)
        ActivityConfiguration(for: AlarmAttributes<CookingData>.self) { context in
            // ロック画面での表示を定義
            // context.attributesでアラームの設定(タイトルや色)
            lockScreenView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            // Dynamic Islandに表示されるUI
            // https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
            // https://qiita.com/Cychow/items/6ece2955e809ef136bc2
            DynamicIsland {
                // 左側の領域
                DynamicIslandExpandedRegion(.leading) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                }
                // 右側の領域
                DynamicIslandExpandedRegion(.trailing) {
                    cookingMethod(metadata: context.attributes.metadata)
                }
                // 下側の領域
                DynamicIslandExpandedRegion(.bottom) {
                    bottomView(attributes: context.attributes, state: context.state)
                }
                // コンパクト表示時のUI
            } compactLeading: {
                countdown(state: context.state, maxWidth: 44)
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                AlarmProgressView(
                    cookingMethod: context.attributes.metadata?.method,
                    mode: context.state.mode,
                    tint: context.attributes.tintColor)
                // 最小表示時のUI
            } minimal: {
                AlarmProgressView(
                    cookingMethod: context.attributes.metadata?.method,
                    mode: context.state.mode,
                    tint: context.attributes.tintColor)
            }
            // Dynamic Islandの背景色や枠線の色
            .keylineTint(context.attributes.tintColor)
        }
    }

    // ロック画面でのUI
    func lockScreenView(attributes: AlarmAttributes<CookingData>, state: AlarmPresentationState)
        -> some View
    {
        VStack {
            HStack(alignment: .top) {
                alarmTitle(attributes: attributes, state: state)
                Spacer()
                cookingMethod(metadata: attributes.metadata)
            }

            bottomView(attributes: attributes, state: state)
        }
        .padding(.all, 12)
    }

    func bottomView(attributes: AlarmAttributes<CookingData>, state: AlarmPresentationState)
        -> some View
    {
        HStack {
            countdown(state: state, maxWidth: 150)
                .font(.system(size: 40, design: .rounded))
            Spacer()
            AlarmControls(presentation: attributes.presentation, state: state)
        }
    }
    // アラームの状態に応じて表示を切り替え
    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now...countdown.fireDate, countsDown: true)
            case .paused(let state):
                let remaining = Duration.seconds(
                    state.totalCountdownDuration - state.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern =
                    remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
            default:
                EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }

    @ViewBuilder func alarmTitle(
        attributes: AlarmAttributes<CookingData>, state: AlarmPresentationState
    ) -> some View {
        let title: LocalizedStringResource? =
            switch state.mode {
            case .countdown:
                attributes.presentation.countdown?.title
            case .paused:
                attributes.presentation.paused?.title
            default:
                nil
            }

        Text(title ?? "")
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
            .padding(.leading, 6)
    }

    @ViewBuilder func cookingMethod(metadata: CookingData?) -> some View {
        if let method = metadata?.method {
            HStack(spacing: 4) {
                Text(method.rawValue.localizedCapitalized)
                Image(systemName: method.icon)
            }
            .font(.body)
            .fontWeight(.medium)
            .lineLimit(1)
            .padding(.trailing, 6)
        } else {
            EmptyView()
        }
    }
}

// 進行状況を円形のプログレスバーで表示
struct AlarmProgressView: View {
    var cookingMethod: CookingData.Method?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                ProgressView(
                    timerInterval: Date.now...countdown.fireDate,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: cookingMethod?.rawValue ?? "")
                            .scaleEffect(0.9)
                    })
            case .paused(let pausedState):
                let remaining =
                    pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                ProgressView(
                    value: remaining,
                    total: pausedState.totalCountdownDuration,
                    label: { EmptyView() },
                    currentValueLabel: {
                        Image(systemName: "pause.fill")
                            .scaleEffect(0.8)
                    })
            default:
                EmptyView()
            }
        }
        .progressViewStyle(.circular)
        .foregroundStyle(tint)
        .tint(tint)
    }
}

// アラームの操作ボタン
struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 4) {
            switch state.mode {
            case .countdown:
                ButtonView(
                    config: presentation.countdown?.pauseButton,
                    intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            case .paused:
                ButtonView(
                    config: presentation.paused?.resumeButton,
                    intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .orange)
            default:
                EmptyView()
            }

            ButtonView(
                config: presentation.alert.stopButton,
                intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
        }
    }
}

struct ButtonView<I>: View where I: AppIntent {
    var config: AlarmButton
    var intent: I
    var tint: Color

    init?(config: AlarmButton?, intent: I, tint: Color) {
        guard let config else { return nil }
        self.config = config
        self.intent = intent
        self.tint = tint
    }

    var body: some View {
        Button(intent: intent) {
            Label(config.text, systemImage: config.systemImageName)
                .lineLimit(1)
        }
        .tint(tint)
        .buttonStyle(.borderedProminent)
        .frame(width: 96, height: 30)
    }
}
