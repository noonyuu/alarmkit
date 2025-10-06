import AlarmKit
import SwiftUI

struct AlarmView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            VStack {
                content
                    .navigationTitle("Alarms")
                    .navigationBarTitleDisplayMode(.inline)
                Button {
                    viewModel.scheduleAlertOnly()
                } label: {
                    Label("Add Alarm", systemImage: "plus")
                }

                Spacer()

                Button {
                    viewModel.scheduleCustomButtonAlert()
                } label: {
                    Label("Custom", systemImage: "alarm")
                }
            }
        }
    }

    @ViewBuilder var content: some View {
        if viewModel.hasUpcomingAlerts {
            alarmList(alarms: Array(viewModel.alarmsMap.values))
        }
    }

    func alarmList(alarms: [AlarmViewModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }.onDelete { indexSet in
                indexSet.forEach { idx in
                    viewModel.unscheduleAlarm(with: alarms[idx].0.id)
                }
            }
        }
    }
}

extension TimeInterval {
    func customFormatted() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? self.formatted()
    }
}
