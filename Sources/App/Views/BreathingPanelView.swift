import SwiftUI

/// 呼吸球视图 — 桌面浮动球，只显示呼吸圆环 + 当前阶段秒数
struct BreathingPanelView: View {
    @ObservedObject private var engine = BreathingEngine.shared

    var body: some View {
        BreathingCircle(
            phase: engine.phase,
            progress: engine.phaseProgress,
            secondsText: ballText
        )
        .frame(width: 240, height: 240)
    }

    private var ballText: String? {
        switch engine.phase {
        case .countdown(let n): return "\(n)"
        case .inhale, .exhale:  return "\(engine.currentPhaseSecondsRemaining)"
        case .paused:           return "‖"
        default:                return nil
        }
    }
}

// MARK: - 预览

struct BreathingPanelView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            BreathingPanelView()
        }
        .frame(width: 240, height: 240)
    }
}
