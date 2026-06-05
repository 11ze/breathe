import AppKit

/// 音频管理器 — 使用 NSSound 播放系统音效
/// 移植自 breathe-cli 的 afplay -v 0.3 调用
@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published private(set) var isMuted: Bool = false

    /// 音量 0.3，与 breathe-cli 的 afplay -v 0.3 一致
    private let volume: Float = 0.3

    /// 吸气音效（Tink = CLI 的 /System/Library/Sounds/Tink.aiff）
    private let inhaleSoundName = "Tink"
    /// 呼气音效（Pop = CLI 的 /System/Library/Sounds/Pop.aiff）
    private let exhaleSoundName = "Pop"

    private init() {}

    /// 切换静音
    func toggleMute() {
        isMuted.toggle()
    }

    /// 设置静音状态
    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    /// 播放吸气音效
    func playInhale() {
        guard !isMuted else { return }
        playSound(named: inhaleSoundName)
    }

    /// 播放呼气音效
    func playExhale() {
        guard !isMuted else { return }
        playSound(named: exhaleSoundName)
    }

    private func playSound(named name: String) {
        guard let sound = NSSound(named: name) else { return }
        sound.volume = volume
        sound.play()
    }
}
