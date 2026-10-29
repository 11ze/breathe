import SwiftUI

/// 会话历史视图，自定义标题栏与表格按设计稿一比一实现。
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
            BreatheWindowTitlebar(
                title: "历史记录",
                onClose: { windowBox.window?.performClose(nil) },
                onMinimize: { windowBox.window?.miniaturize(nil) },
                onZoom: { windowBox.window?.zoom(nil) }
            )

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
            cell("日期", width: HistoryColumn.date)
            cell("时间", width: HistoryColumn.time)
            cell("预设", width: HistoryColumn.preset)
            cell("比例", width: HistoryColumn.ratio)
            cell("目标", width: HistoryColumn.target)
            cell("实际", width: HistoryColumn.actual)
            cell("呼吸", width: HistoryColumn.breaths)
            cell("完成", width: HistoryColumn.complete)
            cell("状态", width: nil)
        }
        .font(.system(size: 11))
        .foregroundColor(BreatheStyle.tableHeaderText)
        .padding(.leading, 24)
        .padding(.trailing, 10)
        .frame(height: 34)
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
    static let date: CGFloat = 153
    static let time: CGFloat = 107
    static let preset: CGFloat = 72
    static let ratio: CGFloat = 71
    static let target: CGFloat = 84
    static let actual: CGFloat = 84
    static let breaths: CGFloat = 72
    static let complete: CGFloat = 82
}

private struct HistoryRow: View {
    let record: SessionRecord
    let index: Int

    @State private var hovering = false

    private var completed: Bool {
        record.status == "completed"
    }

    var body: some View {
        HStack(spacing: 0) {
            text(record.date, width: HistoryColumn.date)
            text(record.time, width: HistoryColumn.time)
            Text(Preset.displayName(for: record.preset))
                .foregroundColor(BreatheStyle.tablePreset)
                .frame(width: HistoryColumn.preset, alignment: .leading)
            text(record.ratio, width: HistoryColumn.ratio)
            text(Self.duration(record.durationTargetSeconds), width: HistoryColumn.target)
            text(Self.duration(record.durationActualSeconds), width: HistoryColumn.actual)
            text("\(record.breaths)", width: HistoryColumn.breaths)
            text("\(record.completionPercent)%", width: HistoryColumn.complete)
            BreatheStatusBadge(completed: completed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: 11).monospacedDigit())
        .foregroundColor(BreatheStyle.ink)
        .padding(.leading, 24)
        .padding(.trailing, 10)
        .frame(height: 40)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }

    private var rowBackground: Color {
        if hovering {
            return BreatheStyle.tableRowHover
        }
        return index % 2 == 1 ? Color(hex: 0xEAF0E5, opacity: 0.13) : Color.clear
    }

    private func text(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .frame(width: width, alignment: .leading)
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
