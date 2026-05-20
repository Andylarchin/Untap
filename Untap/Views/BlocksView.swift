import SwiftUI
import FamilyControls

struct BlocksView: View {
    @EnvironmentObject var appBlocker: AppBlockingManager
    @EnvironmentObject var nfcManager: NFCManager
    @State private var showAppPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BlocksHeaderView(
                    ruleCount: appBlocker.blockingRules.count,
                    tagCount: nfcManager.pairedTags.count
                )

                NFCTagsCard(nfcManager: nfcManager)

                Text("Rules")
                    .monoLabel()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                ForEach(appBlocker.blockingRules) { rule in
                    RuleCardView(rule: rule) {
                        appBlocker.toggleRule(rule)
                    }
                }

                Button {
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                        Text("New rule")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.line, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
            .padding(.bottom, 100)
        }
        .background(Color.bg)
        .sheet(isPresented: $showAppPicker) {
            AppPickerView()
        }
    }
}

// MARK: - Blocks Header
struct BlocksHeaderView: View {
    let ruleCount: Int
    let tagCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(ruleCount) rule\(ruleCount == 1 ? "" : "s") · \(tagCount) tag\(tagCount == 1 ? "" : "s") paired")
                .monoLabel()

            Text("Your ")
                .font(.instrumentSerif(size: 34))
                .foregroundColor(.ink)
            +
            Text("blocks")
                .font(.instrumentSerifItalic(size: 34))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }
}

// MARK: - NFC Tags Card
struct NFCTagsCard: View {
    @ObservedObject var nfcManager: NFCManager
    @State private var showNamingSheet = false
    @State private var pendingTagId: String?
    @State private var tagName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 16))
                        .foregroundColor(.ink2)

                    Text("Paired NFC tags")
                        .monoLabel()
                }

                Spacer()

                Button {
                    nfcManager.startPairing()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Pair tag")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule()
                            .stroke(Color.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    )
                }
            }
            .padding(.bottom, 10)

            if nfcManager.pairedTags.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "wave.3.right")
                            .font(.system(size: 24))
                            .foregroundColor(.ink3)
                        Text("No tags paired yet")
                            .font(.system(size: 13))
                            .foregroundColor(.ink3)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(nfcManager.pairedTags) { tag in
                    NFCTagRow(tag: tag) {
                        nfcManager.unpairTag(tag)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .onChange(of: nfcManager.lastPairedTagId) { _, newValue in
            if let id = newValue {
                pendingTagId = id
                tagName = ""
                showNamingSheet = true
                nfcManager.lastPairedTagId = nil
            }
        }
        .sheet(isPresented: $showNamingSheet) {
            TagNamingSheet(tagName: $tagName) {
                if let id = pendingTagId {
                    let name = tagName.trimmingCharacters(in: .whitespaces)
                    nfcManager.pairTag(
                        identifier: id,
                        name: name.isEmpty ? "My Tag" : name
                    )
                    pendingTagId = nil
                }
                showNamingSheet = false
            }
        }
    }
}

struct NFCTagRow: View {
    let tag: PairedNFCTag
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.sageSoft)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 18))
                        .foregroundColor(.sageDeep)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(tag.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.ink)

                Text("Paired \(tag.pairedDate.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 12))
                    .foregroundColor(.ink3)
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.ink3)
            }
        }
    }
}

// MARK: - Tag Naming Sheet
struct TagNamingSheet: View {
    @Binding var tagName: String
    var onSave: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.sageSoft)
                            .frame(width: 80, height: 80)

                        Image(systemName: "wave.3.right")
                            .font(.system(size: 34))
                            .foregroundColor(.sageDeep)
                    }

                    Text("Tag detected")
                        .font(.instrumentSerif(size: 28))
                        .foregroundColor(.ink)

                    Text("Give this tag a name so you can identify it")
                        .font(.system(size: 14))
                        .foregroundColor(.ink3)
                }
                .padding(.top, 20)

                TextField("e.g. Desk tag, Bedroom tag", text: $tagName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color.bg2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .focused($isFocused)

                Button {
                    onSave()
                } label: {
                    Text("Pair this tag")
                        .font(.geist(size: 15, weight: .semibold))
                        .foregroundColor(.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(Color.bg)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            isFocused = true
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Rule Card
struct RuleCardView: View {
    let rule: BlockingRule
    var onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(rule.name)
                        .font(.instrumentSerif(size: 22))
                        .foregroundColor(.ink)

                    Text(rule.description)
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { rule.isActive },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SageToggleStyle())
            }

            HStack(spacing: 6) {
                ForEach(rule.apps.prefix(4), id: \.self) { app in
                    AppIconView(name: app, size: 30)
                }

                if rule.apps.count > 4 {
                    Text("+\(rule.apps.count - 4)")
                        .font(.geistMono(size: 12))
                        .foregroundColor(.ink3)
                        .frame(width: 30, height: 30)
                        .background(Color.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }

            Divider()

            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(rule.schedule)
                }
                .font(.geistMono(size: 11))
                .foregroundColor(.ink3)

                Spacer()

                Text(rule.isActive ? "● ON" : "○ OFF")
                    .font(.geistMono(size: 11))
                    .foregroundColor(rule.isActive ? .sageDeep : .ink3)
            }
        }
        .padding(18)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.line, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .fill(rule.accentColor)
                .frame(width: 3)
                .padding(.vertical, 18),
            alignment: .leading
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    let name: String
    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.23)
            .fill(appColor)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: appIcon)
                    .font(.system(size: size * 0.47))
                    .foregroundColor(.white)
            )
    }

    private var appColor: Color {
        switch name.lowercased() {
        case "instagram": return Color(hex: "E4405F")
        case "tiktok": return Color(hex: "000000")
        case "x", "twitter": return Color(hex: "1DA1F2")
        case "reddit": return Color(hex: "FF4500")
        case "youtube": return Color(hex: "FF0000")
        case "facebook": return Color(hex: "1877F2")
        case "linkedin": return Color(hex: "0A66C2")
        default: return Color.gray
        }
    }

    private var appIcon: String {
        switch name.lowercased() {
        case "instagram": return "camera.fill"
        case "tiktok": return "play.rectangle.fill"
        case "x", "twitter": return "bubble.left.fill"
        case "reddit": return "list.bullet"
        case "youtube": return "play.fill"
        case "facebook": return "person.2.fill"
        case "linkedin": return "briefcase.fill"
        default: return "app.fill"
        }
    }
}

// MARK: - Sage Toggle Style
struct SageToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.sage : Color.bg2)
                    .frame(width: 44, height: 26)

                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
                    .offset(x: configuration.isOn ? 9 : -9)
            }
            .animation(.spring(response: 0.2), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

// MARK: - App Picker View
struct AppPickerView: View {
    @EnvironmentObject var appBlocker: AppBlockingManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Select apps to block")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(.ink)
                    .padding(.top, 20)

                FamilyActivityPicker(selection: $appBlocker.selectedApps)
                    .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    BlocksView()
        .environmentObject(AppBlockingManager.shared)
        .environmentObject(NFCManager.shared)
}
