import SwiftUI

/// 动画呼吸圆环 — GUI 版本的标志性视觉元素
/// 替代 CLI 的文字进度条，用缩放 + 渐变表示呼吸阶段
struct BreathingCircle: View {
    let phase: BreathingPhase
    let progress: Double // 0.0~1.0
    var secondsText: String? = nil

    /// 圆环基础大小
    private let baseSize: CGFloat = 200

    var body: some View {
        let (scale, colors) = stateStyle

        ZStack {
            // 外圈光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.0.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: baseSize * scale * 0.3,
                        endRadius: baseSize * scale * 0.6
                    )
                )
                .frame(width: baseSize * 1.2, height: baseSize * 1.2)

            // 主圆环
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.0, colors.1],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * scale * 0.5
                    )
                )
                .frame(width: baseSize * scale, height: baseSize * scale)

            // 秒数文字
            if let text = secondsText {
                Text(text)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: progress)
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    /// 根据阶段返回 (缩放比例, 渐变颜色对)
    private var stateStyle: (CGFloat, (Color, Color)) {
        switch phase {
        case .idle:
            // 30% 灰色，静止
            return (0.3, (Color.gray.opacity(0.6), Color.gray.opacity(0.3)))
        case .countdown:
            // 50% 蓝色脉动
            return (0.5, (Color.blue.opacity(0.5), Color.blue.opacity(0.2)))
        case .inhale:
            // 30% → 100% 青色渐变（吸气膨胀）
            let scale = CGFloat(0.3 + 0.7 * progress)
            return (scale, (Color.cyan.opacity(0.8), Color.teal.opacity(0.4)))
        case .exhale:
            // 100% → 30% 绿色渐变（呼气收缩）
            let scale = CGFloat(1.0 - 0.7 * progress)
            return (scale, (Color.green.opacity(0.7), Color.mint.opacity(0.3)))
        case .paused:
            // 50% 琥珀色（暂停）
            return (0.5, (Color.orange.opacity(0.6), Color.yellow.opacity(0.3)))
        }
    }
}

// MARK: - 预览

struct BreathingCircle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            BreathingCircle(phase: .idle, progress: 0)
            BreathingCircle(phase: .countdown(3), progress: 0.5, secondsText: "3")
            BreathingCircle(phase: .inhale, progress: 0.7, secondsText: "2")
            BreathingCircle(phase: .exhale, progress: 0.4, secondsText: "4")
            BreathingCircle(phase: .paused(.inhale), progress: 0.5, secondsText: "‖")
        }
        .frame(width: 300, height: 800)
        .background(Color.black)
    }
}
