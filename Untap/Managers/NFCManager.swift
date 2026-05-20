import Foundation
import CoreNFC
import UIKit
import CoreHaptics
import AudioToolbox

class NFCManager: NSObject, ObservableObject {
    static let shared = NFCManager()

    enum ScanMode {
        case toggle
        case pair
    }

    @Published var isScanning = false
    @Published var lastScannedTag: String?
    @Published var lastPairedTagId: String?
    @Published var errorMessage: String?
    @Published var pairedTags: [PairedNFCTag] = []

    private var tagSession: NFCTagReaderSession?
    private var hapticEngine: CHHapticEngine?
    private var scanMode: ScanMode = .toggle

    private override init() {
        super.init()
        loadPairedTags()
        prepareHapticEngine()
    }

    // MARK: - Public Methods

    var isNFCAvailable: Bool {
        NFCTagReaderSession.readingAvailable
    }

    var hasPairedTags: Bool {
        !pairedTags.isEmpty
    }

    func startScanning() {
        startScan(mode: .toggle)
    }

    func startPairing() {
        startScan(mode: .pair)
    }

    func stopScanning() {
        tagSession?.invalidate()
        tagSession = nil
        isScanning = false
    }

    func pairTag(identifier: String, name: String) {
        guard !pairedTags.contains(where: { $0.identifier == identifier }) else { return }
        let tag = PairedNFCTag(
            identifier: identifier,
            name: name,
            pairedDate: Date()
        )
        pairedTags.append(tag)
        savePairedTags()
    }

    func unpairTag(_ tag: PairedNFCTag) {
        pairedTags.removeAll { $0.id == tag.id }
        savePairedTags()
    }

    func unpairTag(identifier: String) {
        pairedTags.removeAll { $0.identifier == identifier }
        savePairedTags()
    }

    // MARK: - Private Methods

    private func startScan(mode: ScanMode) {
        guard isNFCAvailable else {
            errorMessage = "NFC is not available on this device"
            return
        }

        scanMode = mode
        try? hapticEngine?.start()

        switch mode {
        case .toggle:
            if pairedTags.isEmpty {
                errorMessage = "Pair a tag first in the Blocks tab"
                return
            }
        case .pair:
            break
        }

        tagSession = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693], delegate: self)

        switch mode {
        case .toggle:
            tagSession?.alertMessage = "Hold your iPhone near your paired NFC tag"
        case .pair:
            tagSession?.alertMessage = "Hold your iPhone near the NFC tag you want to pair"
        }

        tagSession?.begin()
        isScanning = true
    }

    private func uidString(from data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private func loadPairedTags() {
        if let data = UserDefaults.standard.data(forKey: "pairedNFCTags"),
           let tags = try? JSONDecoder().decode([PairedNFCTag].self, from: data) {
            pairedTags = tags
        }
    }

    private func savePairedTags() {
        if let data = try? JSONEncoder().encode(pairedTags) {
            UserDefaults.standard.set(data, forKey: "pairedNFCTags")
        }
    }

    private func handleTagIdentifier(_ identifier: String) {
        DispatchQueue.main.async {
            switch self.scanMode {
            case .pair:
                if self.pairedTags.contains(where: { $0.identifier == identifier }) {
                    self.tagSession?.alertMessage = "This tag is already paired."
                } else {
                    self.playTapFeedback()
                    self.lastPairedTagId = identifier
                    self.tagSession?.alertMessage = "Tag detected! Name it to finish pairing."
                }
                self.tagSession?.invalidate()

            case .toggle:
                if self.pairedTags.contains(where: { $0.identifier == identifier }) {
                    self.playTapFeedback()
                    self.lastScannedTag = identifier
                    self.tagSession?.alertMessage = "Tag recognized! Blocking toggled."
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    self.tagSession?.alertMessage = "Unrecognized tag. Pair it first in the Blocks tab."
                }
                self.tagSession?.invalidate()
            }
        }
    }

    private func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine?.resetHandler = { [weak self] in
                try? self?.hapticEngine?.start()
            }
            hapticEngine?.stoppedHandler = { _ in }
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    private func playTapFeedback() {
        playPremiumHaptic()
        playTapSound()
    }

    private func playPremiumHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        do {
            let sharpHit = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            )

            let deepThud = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.08
            )

            let confirmPulse = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.15,
                duration: 0.12
            )

            let snap = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ],
                relativeTime: 0.32
            )

            let pattern = try CHHapticPattern(events: [sharpHit, deepThud, confirmPulse, snap], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func playTapSound() {
        let soundID: SystemSoundID = 1306
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension NFCManager: NFCTagReaderSessionDelegate {

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DispatchQueue.main.async {
            self.isScanning = true
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false

            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorUserCanceled ||
               nfcError.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                return
            }

            self.errorMessage = error.localizedDescription
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }

            if error != nil {
                session.invalidate(errorMessage: "Connection failed. Try again.")
                return
            }

            let uid: String
            switch tag {
            case .miFare(let miFareTag):
                uid = self.uidString(from: miFareTag.identifier)
            case .iso7816(let iso7816Tag):
                uid = self.uidString(from: iso7816Tag.identifier)
            case .iso15693(let iso15693Tag):
                uid = self.uidString(from: iso15693Tag.identifier)
            case .feliCa(let feliCaTag):
                uid = self.uidString(from: feliCaTag.currentIDm)
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag type.")
                return
            }

            self.handleTagIdentifier(uid)
        }
    }
}

// MARK: - Models
struct PairedNFCTag: Codable, Identifiable {
    let id: UUID
    let identifier: String
    let name: String
    let pairedDate: Date

    init(identifier: String, name: String, pairedDate: Date) {
        self.id = UUID()
        self.identifier = identifier
        self.name = name
        self.pairedDate = pairedDate
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let nfcTagScanned = Notification.Name("nfcTagScanned")
}
