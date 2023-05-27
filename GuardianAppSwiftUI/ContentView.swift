//
//  ContentView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 5/19/23.
//

import SwiftUI
import Guardian

struct ContentView: View {
    private static let RSA_KEY_PUBLIC_TAG = "PUBLIC_TAG"
    private static let RSA_KEY_PRIVATE_TAG = "PRIVATE_TAG"
    @EnvironmentObject var notificationCenter: NotificationCenter
    @State private var isSheetPresented = false
    @State private var isPresentingScanner = false
    @State private var showAlert: Bool = false
    @State private var messageForAlert:String = ""
    @State private var notEnrolled:Bool = false
    @State private var enrolled : GuardianState? = AppDelegate.state

    var body: some View {
        if notificationCenter.authenticationNotification != nil {
            NotificationView().environmentObject(notificationCenter)
        }
        else {
            if(enrolled == nil) {
                VStack {
                    Button(action: {
                        self.isPresentingScanner = true
                    }) {
                        Text("Scan QR Code")
                    }
                    .sheet(isPresented: $isPresentingScanner) {
                        ScannerView() { result in
                            if let result = result {
                                self.processEnrollment(with: result)
                            }
                            self.isPresentingScanner = false
                        }
                    }
                    
                }.alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Message"),
                        message: Text(""),
                        dismissButton: .default(Text("OK"))
                    )
                }
            } else {
                EnrollmentView(enrolled: self.$enrolled)
            
            }

        }
    }
    
    func processEnrollment(with string: String) {
        
        readerStuff(barcode: string)

        }
    
    func readerStuff(barcode: String) {
        let barCodeUri = barcode
            
        guard let signingKey = try? KeychainRSAPrivateKey.new(with: ContentView.RSA_KEY_PRIVATE_TAG),
                    let verificationKey = try? signingKey.verificationKey() else { return }

                let request = Guardian
            .enroll(forDomain: AppDelegate.guardianDomain, usingUri: barCodeUri , notificationToken: AppDelegate.pushToken!, signingKey: signingKey, verificationKey: verificationKey)
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
                            self.showAlert = true
                            self.messageForAlert = "Enroll failed -> \(cause)"
                        case .success(let enrollment):
                            
                                AppDelegate.state = GuardianState(identifier: enrollment.id, localIdentifier: enrollment.localIdentifier, token: enrollment.deviceToken, keyTag: signingKey.tag, otp: enrollment.totp)
                                self.enrolled = AppDelegate.state
                        
                            
                        }
                }
    }
    
}

struct PageView: View {
     @State private var selection  = 0
    @State private var localSelectionState = 0
    @State private var showAlert: Bool = false
    var body: some View {
        
                     
        TabView(selection: $selection) {
            ForEach(0..<30) { i in
                ZStack {
                    Color.secondary
                    Text("Row: \(i)").foregroundColor(Color(UIColor.systemBackground))
                }.clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                //.scaleEffect((selection == i) ? 1.0 :  0.8)
            }
            .padding(.all, 10)
        }.onChange(of: selection, perform: { value in
            withAnimation {
                localSelectionState  = value
            }
        })
        .frame(width: UIScreen.main.bounds.width - 200, height: 200)
        .tabViewStyle(PageTabViewStyle())
        
        
    }
}


struct PageView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
        LazyHStack {
            PageView()
        }
    }
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
