import SwiftUI
import MWDATCore

@main
struct MWDATBugTestApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onOpenURL { url in
                    viewModel.log("Deep link received: \(url)")
                    Task {
                        do {
                            let handled = try await Wearables.shared.handleUrl(url)
                            await viewModel.log("handleUrl result: \(handled)")
                        } catch {
                            await viewModel.log("handleUrl error: \(error)")
                        }
                    }
                }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var logs: [String] = []
    @Published var configureError: String?
    @Published var registrationState: String = "unknown"
    @Published var plistValues: [String: String] = [:]

    private var registrationToken: AnyListenerToken?

    init() {
        readPlistValues()
        configureSdk()
        listenRegistrationState()
        // Auto-trigger registration after 2s delay for automated testing
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await self.register()
        }
    }

    func readPlistValues() {
        guard let mwdat = Bundle.main.infoDictionary?["MWDAT"] as? [String: Any] else {
            log("⚠️ MWDAT key not found in Info.plist")
            return
        }
        let metaAppId = mwdat["MetaAppID"] as? String ?? "(nil)"
        let clientToken = mwdat["ClientToken"] as? String ?? "(nil)"
        let teamId = mwdat["TeamID"] as? String ?? "(nil)"
        let urlScheme = mwdat["AppLinkURLScheme"] as? String ?? "(nil)"

        plistValues = [
            "MetaAppID": metaAppId,
            "ClientToken": clientToken,
            "TeamID": teamId,
            "AppLinkURLScheme": urlScheme
        ]

        log("Plist MetaAppID: \"\(metaAppId)\"")
        log("Plist ClientToken: \"\(clientToken)\"")
        log("Plist TeamID: \"\(teamId)\"")
    }

    func configureSdk() {
        do {
            try Wearables.configure()
            log("✅ Wearables.configure() succeeded")
            configureError = nil
        } catch {
            let msg = "❌ Wearables.configure() failed: \(error)"
            log(msg)
            configureError = "\(error)"
        }
    }

    func listenRegistrationState() {
        registrationToken = Wearables.shared.addRegistrationStateListener { [weak self] state in
            Task { @MainActor in
                let stateStr: String
                switch state {
                case .unavailable: stateStr = "unavailable"
                case .available: stateStr = "available"
                case .registering: stateStr = "registering"
                case .registered: stateStr = "registered"
                @unknown default: stateStr = "unknown(\(state))"
                }
                self?.registrationState = stateStr
                self?.log("Registration state → \(stateStr)")
            }
        }
    }

    func register() {
        log("Calling startRegistration()...")
        Task {
            do {
                try await Wearables.shared.startRegistration()
                log("✅ startRegistration() completed")
            } catch let regError as RegistrationError {
                log("❌ RegistrationError: \(regError) (description: \(regError.description))")
            } catch {
                log("❌ startRegistration() error: \(type(of: error)) — \(error)")
            }
        }
    }

    func unregister() {
        log("Calling startUnregistration()...")
        Task {
            do {
                try await Wearables.shared.startUnregistration()
                log("✅ startUnregistration() completed")
            } catch {
                log("❌ startUnregistration() error: \(type(of: error)) — \(error)")
            }
        }
    }

    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(timestamp)] \(message)"
        logs.append(entry)
        print(entry)
    }
}
