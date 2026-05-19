import Foundation
import CoreNFC
import UIKit
import CoreHaptics
import AudioToolbox

class NFCManager: NSObject, ObservableObject {
    static let shared = NFCManager()

    @Published var isScanning = false
    @Published var lastScannedTag: String?
    @Published var errorMessage: String?
    @Published var pairedTags: [PairedNFCTag] = []

    private var session: NFCNDEFReaderSession?
    private var hapticEngine: CHHapticEngine?

    private override init() {
        super.init()
        loadPairedTags()
        prepareHapticEngine()
    }

    // MARK: - Public Methods

    /// Check if NFC is available on this device
    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    /// Start scanning for NFC tags
    func startScanning() {
        guard isNFCAvailable else {
            errorMessage = "NFC is not available on this device"
            return
        }

        try? hapticEngine?.start()

        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )

        session?.alertMessage = "Hold your iPhone near the NFC tag to toggle app blocking"
        session?.begin()
        isScanning = true
    }

    /// Stop the current NFC scanning session
    func stopScanning() {
        session?.invalidate()
        session = nil
        isScanning = false
    }

    /// Pair a new NFC tag with a blocking rule
    func pairTag(identifier: String, name: String, ruleId: UUID) {
        let tag = PairedNFCTag(
            identifier: identifier,
            name: name,
            ruleId: ruleId,
            pairedDate: Date()
        )
        pairedTags.append(tag)
        savePairedTags()
    }

    /// Remove a paired NFC tag
    func unpairTag(identifier: String) {
        pairedTags.removeAll { $0.identifier == identifier }
        savePairedTags()
    }

    // MARK: - Private Methods

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

    private func processTag(identifier: String) {
        DispatchQueue.main.async {
            self.playTapFeedback()
            self.lastScannedTag = identifier

            if let pairedTag = self.pairedTags.first(where: { $0.identifier == identifier }) {
                NotificationCenter.default.post(
                    name: .nfcTagScanned,
                    object: nil,
                    userInfo: ["tagId": identifier, "ruleId": pairedTag.ruleId]
                )
            } else {
                NotificationCenter.default.post(
                    name: .nfcTagScanned,
                    object: nil,
                    userInfo: ["tagId": identifier, "isNew": true]
                )
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
            // Sharp initial hit
            let sharpHit = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            )

            // Warm deep thud
            let deepThud = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.08
            )

            // Rising confirmation pulse
            let confirmPulse = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.15,
                duration: 0.12
            )

            // Final crisp snap
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
        // Use the Tink system sound — a clean, minimal, premium-feeling tap
        let soundID: SystemSoundID = 1306
        AudioServicesPlaySystemSound(soundID)
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCManager: NFCNDEFReaderSessionDelegate {

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Process NDEF messages
        for message in messages {
            for record in message.records {
                if let identifier = String(data: record.identifier, encoding: .utf8) {
                    processTag(identifier: identifier)
                    return
                }
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

                // Read the tag
                tag.readNDEF { message, error in
                    if let error = error {
                        // Even if reading fails, we can use the tag's UID
                        // Generate a unique identifier from the tag
                        let tagIdentifier = UUID().uuidString
                        self?.processTag(identifier: tagIdentifier)
                        session.alertMessage = "Tag recognized! Blocking toggled."
                        session.invalidate()
                        return
                    }

                    if let message = message {
                        for record in message.records {
                            // Try to get a meaningful identifier
                            if let payload = String(data: record.payload, encoding: .utf8) {
                                self?.processTag(identifier: payload)
                            } else {
                                // Use record type or generate ID
                                let identifier = record.identifier.isEmpty
                                    ? UUID().uuidString
                                    : String(data: record.identifier, encoding: .utf8) ?? UUID().uuidString
                                self?.processTag(identifier: identifier)
                            }
                        }
                    }

                    session.alertMessage = "Tag recognized! Blocking toggled."
                    session.invalidate()
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false

            // Check if it was cancelled by user
            if let nfcError = error as? NFCReaderError,
               nfcError.code == .readerSessionInvalidationErrorUserCanceled {
                // User cancelled, no error to show
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
}

// MARK: - Models
struct PairedNFCTag: Codable, Identifiable {
    let id: UUID
    let identifier: String
    let name: String
    let ruleId: UUID
    let pairedDate: Date

    init(identifier: String, name: String, ruleId: UUID, pairedDate: Date) {
        self.id = UUID()
        self.identifier = identifier
        self.name = name
        self.ruleId = ruleId
        self.pairedDate = pairedDate
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let nfcTagScanned = Notification.Name("nfcTagScanned")
}
