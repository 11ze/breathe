import Combine
import XCTest
@testable import Breathe

@MainActor
final class AudioManagerTests: XCTestCase {
    func testInitiallyDisabledSoundMutesWithoutUpdatingSettings() {
        let soundEnabled = CurrentValueSubject<Bool, Never>(false)
        var savedValues: [Bool] = []
        let manager = AudioManager(
            soundEnabled: soundEnabled.eraseToAnyPublisher(),
            updateSoundEnabled: { savedValues.append($0) }
        )

        XCTAssertTrue(manager.isMuted)
        XCTAssertTrue(savedValues.isEmpty, "启动时读取声音设置，不应重新保存配置")
    }

    func testSettingsChangeImmediatelyUpdatesMuteState() {
        let soundEnabled = CurrentValueSubject<Bool, Never>(true)
        let manager = AudioManager(
            soundEnabled: soundEnabled.eraseToAnyPublisher(),
            updateSoundEnabled: { soundEnabled.send($0) }
        )

        XCTAssertFalse(manager.isMuted)
        soundEnabled.send(false)
        XCTAssertTrue(manager.isMuted, "关闭声音提示应立即静音")
        soundEnabled.send(true)
        XCTAssertFalse(manager.isMuted, "重新开启声音提示应立即取消静音")
    }
}
