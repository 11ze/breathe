import SwiftUI

/// 会话历史视图
struct HistoryView: View {
    @State private var records: [SessionRecord] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text("会话记录")
                        .font(.system(size: 20, weight: .semibold))
                    Text("每一次呼吸练习，都留在这里。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(26)

            Divider()
            toolbar
            Divider()

            if records.isEmpty {
                emptyView
            } else {
                tableView
            }

            Divider()
            HStack {
                Text("CSV · 与 breathe-cli 兼容")
                Spacer()
                Text("~/.config/breathe/sessions.csv")
                    .textSelection(.enabled)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
        }
        .frame(minWidth: 800, minHeight: 400)
        .background(BreatheStyle.background)
        .tint(BreatheStyle.accent)
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
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - 表格

    private var tableView: some View {
        Table(records) {
            TableColumn("日期") { record in
                Text(record.date)
                    .font(.caption.monospacedDigit())
            }
            .width(min: 90, ideal: 95, max: 110)

            TableColumn("时间") { record in
                Text(record.time)
                    .font(.caption.monospacedDigit())
            }
            .width(min: 65, ideal: 70, max: 85)

            TableColumn("预设") { record in
                Text(record.preset)
                    .font(.caption)
                    .foregroundColor(BreatheStyle.accent)
            }
            .width(min: 65, ideal: 75, max: 95)

            TableColumn("比例") { record in
                Text(record.ratio)
                    .font(.caption)
            }
            .width(min: 45, ideal: 50, max: 65)

            TableColumn("目标") { record in
                Text("\(record.durationTargetSeconds / 60):\(String(format: "%02d", record.durationTargetSeconds % 60))")
                    .font(.caption.monospacedDigit())
            }
            .width(min: 50, ideal: 55, max: 65)

            TableColumn("实际") { record in
                Text("\(record.durationActualSeconds / 60):\(String(format: "%02d", record.durationActualSeconds % 60))")
                    .font(.caption.monospacedDigit())
            }
            .width(min: 50, ideal: 55, max: 65)

            TableColumn("呼吸") { record in
                Text("\(record.breaths)")
                    .font(.caption)
            }
            .width(min: 40, ideal: 45, max: 55)

            TableColumn("完成") { record in
                Text("\(record.completionPercent)%")
                    .font(.caption)
                    .foregroundColor(record.completionPercent == 100 ? .green : .orange)
            }
            .width(min: 45, ideal: 50, max: 60)

            TableColumn("状态") { record in
                Text(record.status == "completed" ? "已完成" : "提前结束")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(record.status == "completed" ? BreatheStyle.accent : .orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((record.status == "completed" ? BreatheStyle.accent : .orange).opacity(0.10))
                    .cornerRadius(4)
            }
            .width(min: 75, ideal: 80, max: 95)
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
