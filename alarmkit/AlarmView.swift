import AlarmKit
import SwiftUI

struct AlarmView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Alarms")
                .navigationBarTitleDisplayMode(.inline)
            Button {
                viewModel.scheduleAlertOnly()
            } label: {
                Label("Add Alarm", systemImage: "plus")
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
            ForEach(alarms, id:\.0.id) {(alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }.onDelete { indexSet in
                indexSet.forEach { idx in
                    viewModel.unscheduleAlarm(with: alarms[idx].0.id)
                }
            }
        }
    }
}

extension Alarm {
    var alertingTime: Date? {
        guard let schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
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
