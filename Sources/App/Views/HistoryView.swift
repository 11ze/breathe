import SwiftUI

/// 会话历史视图，主要字段常显，次要字段在记录详情中展开。
struct HistoryView: View {
    @State private var records: [SessionRecord] = []
    @StateObject private var windowBox = BreatheWindowBox()

    private let previewRecords: [SessionRecord]?

    /// `previewRecords` 仅用于 SwiftUI 预览与离屏截图，正常窗口从 CSV 读取。
    init(previewRecords: [SessionRecord]? = nil) {
        self.previewRecords = previewRecords
    }

    var body: some View {
        VStack(spacing: 0) {
            BreatheWindowTitlebar(title: "历史记录") { action in
                BreatheWindowActionHandler.perform(action, on: windowBox.window)
            }

            heading
            toolbar

            if records.isEmpty {
                emptyView
            } else {
                tableHeader
                tableBody
            }

            footer
        }
        .background(BreatheStyle.surface)
        .frame(minWidth: 860, minHeight: 540)
        .background(BreatheWindowAccessor(box: windowBox))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
        )
        .ignoresSafeArea()
        .onAppear(perform: loadRecordsIfNeeded)
    }

    // MARK: - 页头

    private var heading: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text("会话记录")
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundColor(BreatheStyle.ink)
                Text("每一次呼吸练习，都留在这里。")
                    .font(.system(size: 12))
                    .foregroundColor(BreatheStyle.muted)
            }
            Spacer()
        }
        .padding(.top, 28)
        .padding(.horizontal, 26)
        .padding(.bottom, 24)
    }

    // MARK: - 工具栏

    private var toolbar: some View {
        HStack(spacing: 8) {
            Text("\(records.count) 条记录")
                .font(.system(size: 11))
                .foregroundColor(BreatheStyle.muted)
            Spacer()
            BreathePushButton(title: "刷新", action: loadRecords)
            BreathePushButton(title: "导入旧版日志", action: importLegacy)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(BreatheStyle.line).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(BreatheStyle.line).frame(height: 1)
        }
    }

    // MARK: - 表格

    private var tableHeader: some View {
        HStack(spacing: 0) {
            cell("日期与时间", width: HistoryColumn.date)
            cell("预设", width: HistoryColumn.preset)
            cell("实际时长", width: HistoryColumn.actual)
            cell("状态", width: nil)
            Color.clear.frame(width: HistoryColumn.disclosure)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(BreatheStyle.tableHeaderText)
        .padding(.leading, 24)
        .padding(.trailing, 24)
        .frame(height: 38)
        .background(BreatheStyle.tableHeader)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BreatheStyle.tableHeaderLine).frame(height: 1)
        }
    }

    private var tableBody: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.offset) { index, record in
                    HistoryRow(record: record, index: index)
                        .id(record.id)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(BreatheStyle.muted)
            Text("暂无会话记录")
                .font(.system(size: 12))
                .foregroundColor(BreatheStyle.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(55)
    }

    private var footer: some View {
        HStack {
            Text("CSV · 与 breathe-cli 兼容")
            Spacer()
            Text("~/.config/breathe/sessions.csv")
                .textSelection(.enabled)
        }
        .font(.system(size: 10))
        .foregroundColor(BreatheStyle.muted)
        .padding(.horizontal, 24)
        .padding(.vertical, 13)
        .overlay(alignment: .top) {
            Rectangle().fill(BreatheStyle.line).frame(height: 1)
        }
    }

    private func cell(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    // MARK: - 操作

    private func loadRecordsIfNeeded() {
        if let previewRecords = previewRecords {
            records = previewRecords
        } else {
            loadRecords()
        }
    }

    private func loadRecords() {
        guard previewRecords == nil else { return }
        records = SessionLogger.shared.loadAll()
    }

    private func importLegacy() {
        guard previewRecords == nil else { return }
        let count = SessionLogger.shared.importLegacyLog()
        if count > 0 {
            loadRecords()
        }
    }
}

// MARK: - 表格行

private enum HistoryColumn {
    static let date: CGFloat = 280
    static let preset: CGFloat = 156
    static let actual: CGFloat = 156
    static let disclosure: CGFloat = 18
}

private struct HistoryRow: View {
    let record: SessionRecord
    let index: Int

    @State private var hovering = false
    @State private var isExpanded = false

    private var completed: Bool {
        record.status == "completed"
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.date)
                        Text(record.time)
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(BreatheStyle.muted)
                    }
                    .frame(width: HistoryColumn.date, alignment: .leading)
                    Text(Preset.displayName(for: record.preset))
                        .foregroundColor(BreatheStyle.tablePreset)
                        .frame(width: HistoryColumn.preset, alignment: .leading)
                    Text(Self.duration(record.durationActualSeconds))
                        .frame(width: HistoryColumn.actual, alignment: .leading)
                    BreatheStatusBadge(completed: completed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BreatheStyle.muted)
                        .frame(width: HistoryColumn.disclosure)
                }
                .font(.system(size: 13).monospacedDigit())
                .foregroundColor(BreatheStyle.ink)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(rowBackground)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "已展开" : "已收起")
            .accessibilityHint(isExpanded ? "收起会话详情" : "展开会话详情")
            .onHover { hovering = $0 }

            if isExpanded {
                HStack(alignment: .top, spacing: 40) {
                    detail("吸气 / 呼气", value: "\(record.ratio) 秒")
                    detail("目标时长", value: Self.duration(record.durationTargetSeconds))
                    detail("呼吸次数", value: "\(record.breaths) 次")
                    detail("完成比例", value: "\(record.completionPercent)%")
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 15)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.5))
            }

            BreatheDivider()
        }
    }

    private var rowBackground: Color {
        if hovering {
            return BreatheStyle.tableRowHover
        }
        if isExpanded {
            return Color(hex: 0xEDF2E9)
        }
        return index % 2 == 1 ? Color(hex: 0xEAF0E5, opacity: 0.13) : Color.clear
    }

    private func detail(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(BreatheStyle.muted)
            Text(value)
                .font(.system(size: 13).monospacedDigit())
                .foregroundColor(BreatheStyle.ink)
                .textSelection(.enabled)
        }
    }

    private static func duration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - 预览

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView(previewRecords: [
            SessionRecord(date: "2026-10-29", time: "07:30:12", preset: "morning", ratio: "5-5",
                          durationTargetSeconds: 600, durationActualSeconds: 600, breaths: 60,
                          completionPercent: 100, status: "completed"),
            SessionRecord(date: "2026-10-28", time: "18:42:36", preset: "evening", ratio: "4-6",
                          durationTargetSeconds: 900, durationActualSeconds: 504, breaths: 50,
                          completionPercent: 56, status: "ended early (user)")
        ])
        .frame(width: 860, height: 560)
    }
}
