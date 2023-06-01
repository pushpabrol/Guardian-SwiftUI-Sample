//
//  ContentView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 5/19/23.
//

import SwiftUI
import Guardian


class EnrollmentListRefreshManager: ObservableObject {
    @Published var shouldRefresh = false
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

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            if notificationCenter.authenticationNotification != nil {
                NotificationView().environmentObject(notificationCenter)
            }
            else {
                VStack {
                    Button(action: {
                        self.isPresentingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title)
                            Text("Scan QR Code to Enroll")
                                .font(.headline)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
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
                    EnrollmentListView().environmentObject(refreshManager)
                }
                
            }
        }
    }
    
    func processEnrollment(with string: String, completion: @escaping () -> Void) {
        let barCodeUri = string
        print(barCodeUri)
        var datafromUrl = extractEmailAndDomain(from: barCodeUri);
        
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
