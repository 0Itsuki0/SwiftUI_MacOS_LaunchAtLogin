
import SwiftUI
import Combine

@Observable
class ApplicationManager {
    private(set) var launchAtLogin: Bool

    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }
    
    func setLaunchAtLogin(to state: Bool) {
        do {
            state ? try SMAppService.mainApp.register() :  try SMAppService.mainApp.unregister()
        } catch(let error) {
            // If the service is already registered, kSMErrorAlreadyRegistered.
            // If the service isn't approved by the user, this method returns kSMErrorLaunchDeniedByUser.
            //
            // no need to display the error but simply log it for reference
            logger.error(category: category, message: error.localizedDescription)
        }
        
        self.updateCurrentLaunchAtLoginState()
    }
    
    func updateCurrentLaunchAtLoginState() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}

struct SettingsSystemView: View {
    @State private var applicationManager = ApplicationManager()

    // a separate state variable to avoid modifying the actual state directly
    @State private var launchAtLogin = false
    
    // in case user modifies the setting from the system setting directly
    @State private var cancellable: Cancellable?
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common)

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            Toggle(isOn: $launchAtLogin, label: {
                Text("Launch App On Login")
            })
        }
        .onChange(of: applicationManager.launchAtLogin, initial: true, {
            if self.launchAtLogin != applicationManager.launchAtLogin {
                self.launchAtLogin = applicationManager.launchAtLogin
            }
        })
        .onChange(of: self.launchAtLogin, initial: true, {
            if self.launchAtLogin != applicationManager.launchAtLogin {
                self.applicationManager.setLaunchAtLogin(to: self.launchAtLogin)
            }
        })
        .onReceive(timer) { _ in
            self.applicationManager.updateCurrentLaunchAtLoginState()
        }
        .onAppear {
            self.cancellable = self.timer.connect()
        }
        .onDisappear {
            self.cancellable?.cancel()
        }
    }
}
