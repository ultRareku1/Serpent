import AVFoundation

/// Short, locally synthesized tones: no downloads and no audio assets.
@MainActor
final class SoundEngine {
    enum Cue { case start, eat, pause, gameOver, record }
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var available = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.28
        engine.prepare()
    }

    func play(_ cue: Cue, enabled: Bool) {
        guard enabled else { return }
        if !engine.isRunning {
            do { try engine.start(); available = true } catch { available = false }
        }
        guard available else { return }
        let notes: [(Double, Double)]
        switch cue {
        case .start: notes = [(440, 0.06), (660, 0.09)]
        case .eat: notes = [(740, 0.045), (988, 0.065)]
        case .pause: notes = [(392, 0.075)]
        case .gameOver: notes = [(330, 0.09), (262, 0.10), (196, 0.17)]
        case .record: notes = [(523, 0.07), (659, 0.07), (784, 0.07), (1047, 0.14)]
        }
        let total = notes.reduce(0) { $0 + $1.1 }
        let frameCount = AVAudioFrameCount(total * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frameCount
        var cursor = 0
        for (frequency, duration) in notes {
            let count = Int(duration * format.sampleRate)
            for index in 0..<count where cursor + index < Int(frameCount) {
                let t = Double(index) / format.sampleRate
                let envelope = min(1, t / 0.008) * pow(max(0, 1 - t / duration), 1.8)
                samples[cursor + index] = Float(sin(2 * .pi * frequency * t) * envelope * 0.5)
            }
            cursor += count
        }
        player.scheduleBuffer(buffer)
        if !player.isPlaying { player.play() }
    }
}
