import SwiftUI

/// 会话历史视图
struct HistoryView: View {
    @State private var records: [SessionRecord] = []

    var body: some View {
        VStack(spacing: 0) {
            if records.isEmpty {
                emptyView
            } else {
                toolbar
                tableView
            }
        }
        .frame(width: 600, height: 400)
        .onAppear { loadRecords() }
    }

    // MARK: - 空状态

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("暂无会话记录")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - 工具栏

    private var toolbar: some View {
        HStack {
            Text("\(records.count) 条记录")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button("刷新") { loadRecords() }
            Button("导入旧版日志") { importLegacy() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - 表格

    private var tableView: some View {
        Table(records) {
            TableColumn("日期") { record in
                Text(record.date)
                    .font(.caption.monospacedDigit())
            }
            .width(min: 90)

            TableColumn("时间") { record in
                Text(record.time)
                    .font(.caption.monospacedDigit())
            }
            .width(min: 70)

            TableColumn("预设") { record in
                Text(record.preset)
                    .font(.caption)
            }
            .width(min: 70)

            TableColumn("比例") { record in
                Text(record.ratio)
                    .font(.caption)
            }
            .width(min: 50)

            TableColumn("目标") { record in
                Text("\(record.durationTargetSeconds / 60):\(String(format: "%02d", record.durationTargetSeconds % 60))")
                    .font(.caption.monospacedDigit())
            }
            .width(min: 50)

            TableColumn("实际") { record in
                Text("\(record.durationActualSeconds / 60):\(String(format: "%02d", record.durationActualSeconds % 60))")
                    .font(.caption.monospacedDigit())
            }
            .width(min: 50)

            TableColumn("呼吸") { record in
                Text("\(record.breaths)")
                    .font(.caption)
            }
            .width(min: 40)

            TableColumn("完成") { record in
                Text("\(record.completionPercent)%")
                    .font(.caption)
                    .foregroundColor(record.completionPercent == 100 ? .green : .orange)
            }
            .width(min: 45)

            TableColumn("状态") { record in
                Text(record.status == "completed" ? "✓" : "✗")
                    .font(.caption)
                    .foregroundColor(record.status == "completed" ? .green : .red)
            }
            .width(min: 30)
        }
    }

    // MARK: - 操作

    private func loadRecords() {
        records = SessionLogger.shared.loadAll()
    }

    private func importLegacy() {
        let count = SessionLogger.shared.importLegacyLog()
        if count > 0 {
            loadRecords()
        }
    }
}

// MARK: - 预览

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
