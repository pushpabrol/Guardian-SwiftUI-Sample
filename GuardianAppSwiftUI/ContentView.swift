//
//  ContentView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 5/19/23.
//

import SwiftUI
import Guardian
import LocalAuthentication



class EnrollmentListRefreshManager: ObservableObject {
    @Published var shouldRefresh = false
}

enum BiometricAuthenticationResult {
    case none
    case notAvailable
    case failure
}

struct ContentView: View {
    private static let RSA_KEY_PUBLIC_TAG = "PUBLIC_TAG"
    private static let RSA_KEY_PRIVATE_TAG = "PRIVATE_TAG"
    @EnvironmentObject var notificationCenter: NotificationCenter
    @State private var isSheetPresented = false
    @State private var isPresentingScanner = false
    @State private var showAlert: Bool = false
    @State private var messageForAlert:String = ""
    @State private var notEnrolled:Bool = false
    @StateObject private var refreshManager = EnrollmentListRefreshManager()
    @State private var biometricAuthenticationResult: BiometricAuthenticationResult = .none

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            if notificationCenter.authenticationNotification != nil {
                NotificationView().environmentObject(notificationCenter)
            }
            else {
                VStack {
                    HStack {

                        Button(action: {
                            self.isPresentingScanner = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title)
                                Text("Scan QR Code to Enroll")
                                    .font(.headline)
                                Spacer()
                                
                            }
                            .padding()
                            .foregroundColor(.blue)
                        }.onAppear {
                            authenticateOnAppOpen()
                        }
                        .sheet(isPresented: $isPresentingScanner) {
                            ScannerView() { result in
                                if let result = result {
                                    self.processEnrollment(with: result, completion: {
                                        self.isPresentingScanner = false
                                        DispatchQueue.main.async {
                                            self.refreshManager.shouldRefresh = true // Trigger refresh of EnrollmentListView
                                        }
                                        
                                    })
                                }
                                
                            }
                        }
                        Spacer()
                        Image("a0black")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32) // Adjust the size as needed
                                    .padding(.horizontal)
                    }
                    EnrollmentListView().environmentObject(refreshManager)
                }
                
            }
        }.alert(isPresented: $showAlert) {
            switch biometricAuthenticationResult {
            case .notAvailable:
                return Alert(
                    title: Text("Biometric Authentication Not Available"),
                    message: Text("Biometric authentication is not supported or configured on this device."),
                    dismissButton: .default(Text("OK"))
                )
            case .failure:
                return Alert(
                    title: Text("Biometric Authentication Failed"),
                    message: Text("Biometric or Passcode authentication failed. Please relaunch your app and try authenticating with your credentials"),
                    dismissButton: .default(Text("OK")) {
                                    // Code to run when the dismiss button is tapped
                                    // Add your code here
                                    exit(0)
                                }
                )
            default:
                return Alert(
                    title: Text("Alert"),
                    message: Text(messageForAlert),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    func processEnrollment(with string: String, completion: @escaping () -> Void) {
        let barCodeUri = string
        print(barCodeUri)
        let datafromUrl = extractEmailAndDomain(from: barCodeUri);
        
        guard let signingKey = try? KeychainRSAPrivateKey.new(with: ContentView.RSA_KEY_PRIVATE_TAG),
            let verificationKey = try? signingKey.verificationKey() else {
                return
        }

        let request = Guardian.enroll(forDomain: datafromUrl.domain!, usingUri: barCodeUri, notificationToken: AppDelegate.pushToken!, signingKey: signingKey, verificationKey: verificationKey)
        debugPrint(request)
        request
            .on(response: { event in
                guard let data = event.data else { return }
                let body = String(data: data, encoding: .utf8) ?? "INVALID BODY"
                print(body)
            })
            .start { result in
                switch result {
                case .failure(let cause):
                    print("\(cause)")
                    completion()
                case .success(let enrollment):
                    let enrollment = GuardianState(identifier: enrollment.id, localIdentifier: enrollment.localIdentifier, token: enrollment.deviceToken, keyTag: signingKey.tag, otp: enrollment.totp, userEmail: datafromUrl.email ?? "", enrollmentTenantDomain: datafromUrl.domain!)
                    AppDelegate.saveEnrollmentById(enrollment: enrollment)
                    completion()
                }
            }
    }
    
    func extractEmailAndDomain(from urlString: String) -> (email: String?, domain: String?) {
        let percentEncodingRemoved = urlString.removingPercentEncoding!
        let pattern = "otpauth://totp/.+?:(.+?)\\?enrollment_tx_id=.+?&base_url=https?://([^/]+).*"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: percentEncodingRemoved.count)
        guard let match = regex.firstMatch(in: percentEncodingRemoved, options: [], range: range) else {
            return (nil, nil)
        }
        
        let emailRange = match.range(at: 1)
        let domainRange = match.range(at: 2)
        
        if let emailRange = Range(emailRange, in: percentEncodingRemoved),
           let domainRange = Range(domainRange, in: percentEncodingRemoved) {
            let email = String(percentEncodingRemoved[emailRange]).removingPercentEncoding
            let domain = String(percentEncodingRemoved[domainRange])
            return (email, domain)
        }
        
        return (nil, nil)
    }
    
    func authenticateOnAppOpen() {
            let context = LAContext()
            var error: NSError?

            // Check if biometric authentication is available
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                // Biometric authentication is available, perform authentication
                let reason = "Authenticate to access the app"
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            // Authentication successful, proceed with necessary actions
                            // e.g., navigate to the main screen
                            self.showAlert = false

                        } else {
                            // Authentication failed or canceled
                            biometricAuthenticationResult = .failure
                            self.showAlert = true
                        }
                    }
                }
            } else {
                // Biometric authentication is not available or not configured
                biometricAuthenticationResult = .notAvailable
                self.showAlert = true
            }
        }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationCenter())
            .environmentObject(EnrollmentListRefreshManager())
    }
}


class OTPCredential {

    @objc dynamic var algorithmName: String = "sha1"
    @objc dynamic var digits: Int = 6
    @objc dynamic var counter: Int = 0
    @objc dynamic var period: Int = 30
    @objc dynamic var base32Secret: String = ""
    @objc dynamic var otpType: String = "totp"

    @objc dynamic var createdAt: Date = Date(timeIntervalSince1970: 1)
    @objc dynamic var updatedAt: Date? = nil
}
