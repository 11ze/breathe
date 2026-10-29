import SwiftUI

/// 动画呼吸圆环 — 按设计稿的尺寸、配色与缩放曲线实现。
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
                        stops: [
                            .init(color: Color(hex: 0x75B99B, opacity: 0.27), location: 0),
                            .init(color: Color.clear, location: 0.68)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 108
                    )
                )
                .frame(width: 216, height: 216)

            // 主圆球
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.0, colors.1],
                        center: UnitPoint(x: 0.42, y: 0.36),
                        startRadius: 0,
                        endRadius: baseSize * scale * 0.72
                    )
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.19), lineWidth: 20)
                        .blur(radius: 10)
                        .clipShape(Circle())
                )
                .frame(width: baseSize * scale, height: baseSize * scale)

            // 秒数文字
            if let text = secondsText {
                Text(text)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.27), radius: 4, y: 1)
            }
        }
        .frame(width: 240, height: 240)
        .drawingGroup() // 将 20Hz 渐变圆球渲染卸载到 GPU
    }

    /// 根据阶段返回 (缩放比例, 渐变颜色对)
    private var stateStyle: (CGFloat, (Color, Color)) {
        switch phase {
        case .idle:
            return (0.3, (Color.gray.opacity(0.6), Color.gray.opacity(0.3)))
        case .countdown:
            return (0.5, (Color(hex: 0x71A8D9), Color(hex: 0x8FC0DC, opacity: 0.53)))
        case .inhale:
            let scale = CGFloat(0.3 + 0.7 * progress)
            return (scale, (Color(hex: 0x67D79C), Color(hex: 0x58BCA3, opacity: 0.48)))
        case .exhale:
            let scale = CGFloat(1.0 - 0.7 * progress)
            return (scale, (Color(hex: 0xEA8C6F), Color(hex: 0xE8AB79, opacity: 0.53)))
        case .paused:
            return (0.5, (Color(hex: 0xDDA44F), Color(hex: 0xE9CB78, opacity: 0.53)))
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
            BreathingCircle(phase: .paused(.inhale), progress: 0.5, secondsText: "Ⅱ")
        }
        .frame(width: 300, height: 800)
        .background(Color(hex: 0xDDE5DF))
    }
}
