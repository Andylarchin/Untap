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

    private var session: NFCNDEFReaderSession?
    private var hapticEngine: CHHapticEngine?
    private var scanMode: ScanMode = .toggle

    private override init() {
        super.init()
        loadPairedTags()
        prepareHapticEngine()
    }

    // MARK: - Public Methods

    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
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
        session?.invalidate()
        session = nil
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

        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )

        switch mode {
        case .toggle:
            if pairedTags.isEmpty {
                session?.alertMessage = "No tags paired yet. Go to Blocks to pair a tag first."
                session?.invalidate()
                session = nil
                errorMessage = "Pair a tag first in the Blocks tab"
                return
            }
            session?.alertMessage = "Hold your iPhone near your paired NFC tag"
        case .pair:
            session?.alertMessage = "Hold your iPhone near the NFC tag you want to pair"
        }

        session?.begin()
        isScanning = true
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

    private func processTag(identifier: String, session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            switch self.scanMode {
            case .pair:
                if self.pairedTags.contains(where: { $0.identifier == identifier }) {
                    session.alertMessage = "This tag is already paired."
                } else {
                    self.playTapFeedback()
                    self.lastPairedTagId = identifier
                    session.alertMessage = "Tag detected! Name it to finish pairing."
                }
                session.invalidate()

            case .toggle:
                if self.pairedTags.contains(where: { $0.identifier == identifier }) {
                    self.playTapFeedback()
                    self.lastScannedTag = identifier
                    session.alertMessage = "Tag recognized! Blocking toggled."
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    session.alertMessage = "Unrecognized tag. Pair it first in the Blocks tab."
                }
                session.invalidate()
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

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCManager: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                let identifier = extractIdentifier(from: record)
                processTag(identifier: identifier, session: session)
                return
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Query failed: \(error.localizedDescription)")
                    return
                }

                tag.readNDEF { message, error in
                    // Build a stable identifier from the tag data
                    let identifier: String
                    if let message = message, let record = message.records.first {
                        identifier = self?.extractIdentifier(from: record) ?? UUID().uuidString
                    } else {
                        // No NDEF data — use a hash of the tag's description as a fallback
                        identifier = "tag-\(String(describing: tag).hashValue)"
                    }

                    self?.processTag(identifier: identifier, session: session)
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false

            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorUserCanceled {
                return
            }

            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                return
            }

            self.errorMessage = error.localizedDescription
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.isScanning = true
        }
    }

    private func extractIdentifier(from record: NFCNDEFPayload) -> String {
        if let payload = String(data: record.payload, encoding: .utf8), !payload.isEmpty {
            return payload
        }
        if !record.identifier.isEmpty,
           let id = String(data: record.identifier, encoding: .utf8) {
            return id
        }
        return "nfc-\(record.payload.hashValue)"
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
