import SwiftUI
import Combine
import Guardian
import JWTDecode
import LocalAuthentication

struct NotificationView: View {
    @EnvironmentObject var notificationCenter: NotificationCenter
    @State var browserLabel: String = "Unknown"
    @State var location: Location? = nil
    @State var dateLabel: String = ""
    @State var merchantName: String = ""
    @State var paymentAmount: String = ""
    @State var username: String = ""
    @State var account: String = ""
    @State var tenant: String = ""
    @State private var showBiometricPrompt = false
    @State private var authenticationError: Error? = nil
    @State private var isButtonEnabled = true
    @State private var showAllowAlert = false
    @State private var timerAllow: Timer? = nil


    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            
            VStack(spacing: 20) {
                Text("Authentication Request").font(.headline)
                Text("User: \(self.username)").font(.subheadline)
                Text("Tenant: \(self.tenant)").font(.subheadline)
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    Group {
                        Text("Browser")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(browserLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        
                        Text("Location")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(location?.name ?? "Unknown")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("Requested At")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(dateLabel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("Requested")
                            .font(.headline)
                            .padding(.horizontal)
                        Text("\(merchantName) is requesting a payment of \(paymentAmount) from your account: \(account)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    Spacer()

                    HStack(spacing: 50) {
                        Button(action: {
                            guard isButtonEnabled else { return } // Check if the button is already disabled
                            isButtonEnabled = false // Disable the button
                            self.showBiometricPrompt = true
                            
                        }) {
                            Text("Allow")
                                .font(.headline)
                                .padding()
                                .frame(width: 130, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }.disabled(!isButtonEnabled)

                        Button(action: {
                            self.denyAction(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
                            
                        }) {
                            Text("Deny")
                                .font(.headline)
                                .padding()
                                .frame(width: 130, height: 50)
                                .background(Color.gray)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                }
                .padding()
                .background()
                .cornerRadius(10)
                .border(.secondary)
                .shadow(radius: 10)
                .alert(isPresented: $showBiometricPrompt) {
                            biometricPrompt
                            
                        }
            }
            .padding()
            .onAppear {
                if(notificationCenter.authenticationNotification != nil)
                {
                    self.loadData(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
                }
                else {
                    dateLabel = Date().formatted(date: .abbreviated, time: Date.FormatStyle.TimeStyle.standard)
                    merchantName = "blah"
                    paymentAmount = "100"
                    username = "pushp.abrol@gmail.com"
                    account = "10000aedafd"
                    tenant = "auth0.com"
                }
            }

            if showAllowAlert {
                Text("Access Granted. Continue at \(self.merchantName) to complete your transaction!")
                                    .font(.title)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 2.0)))
                                    .zIndex(1) // Ensure the text view is on top of other views
                                    
                                // Transparent overlay view to prevent taps on the underlying content
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {} // Ignore taps on the overlay
                                    .zIndex(2) // Place the overlay above the text view
            }
        }
        
    }

    private var biometricPrompt: Alert {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                authenticationError = error
                showBiometricPrompt = false
                isButtonEnabled = true
                return Alert(title: Text("Error"), message: Text(error?.localizedDescription ?? "Failed to evaluate biometric policy."), dismissButton: .default(Text("OK")))
            }
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to allow the action") { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.allowAction(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
                        self.showAllowAlert = true

                        self.timerAllow?.invalidate()
                        self.timerAllow = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                            self.showAllowAlert = false
                            notificationCenter.authenticationNotification = nil
                        }
                    } else if let error = error {
                        self.authenticationError = error
                    }
                    self.showBiometricPrompt = false
                }
            }
            
        return Alert(title: Text("Biometric Authentication"), message: Text("Authenticate to allow the action"), dismissButton: .default(Text("Cancel")))
        }
    
    func loadData(enrollment: GuardianState?) {
        guard let notification = notificationCenter.authenticationNotification, let enrollment = enrollment else {
            return
        }
        browserLabel = notification.source?.browser?.name ?? "Unknown"
        location = notification.location!
        dateLabel = "\(notification.startedAt.formatted(date: .abbreviated, time: Date.FormatStyle.TimeStyle.standard))"
        self.username = enrollment.userEmail
        self.tenant = enrollment.enrollmentTenantDomain
        
        if( notification.txlnkid != nil) {
            if let url = URL(string: "https://messagestore.desmaximus.com/api/message/".appending(notification.txlnkid!)) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        do {
                            let res = try JSONDecoder().decode(AuthorizationDetails.self, from: data)
                            print(url)
                            print(res.account)
                            DispatchQueue.main.async {
                                self.merchantName = res.creditorName
                                self.paymentAmount = "\(res.transaction_amount)".appending(" USD")
                                self.account = res.account
                               
                            }
                        } catch let error {
                            print(error)
                        }
                        
                    }
                }.resume()
            }
        }
    }

    func allowAction(enrollment: GuardianState?) {
        guard let notification = notificationCenter.authenticationNotification, let enrollment = enrollment else {
            notificationCenter.authenticationNotification = nil
            return
        }
        let request = Guardian
            .authentication(forDomain: enrollment.enrollmentTenantDomain, device: enrollment)
            .allow(notification: notification)
        debugPrint(request)
        request.start { result in
                print(result)
                switch result {
                case .success:
                    print("Allow Success")
                        
                case .failure(let cause):
                    print("Allow failed \(cause)")
                }
        }
    }

    func denyAction(enrollment: GuardianState?) {
        guard let notification = notificationCenter.authenticationNotification, let enrollment = enrollment else {
            notificationCenter.authenticationNotification = nil
            return
        }
        let request = Guardian
            .authentication(forDomain: enrollment.enrollmentTenantDomain, device: enrollment)
            .reject(notification: notification, withReason: "User rejected the notifiation!")
        debugPrint(request)
        request.start { result in
                print(result)
                switch result {
                case .success:
                    print("User rejected the request!")
                    DispatchQueue.main.async {
                        notificationCenter.authenticationNotification = nil
                    }
                case .failure(let cause):
                    print("Reject failed \(cause)")
                }
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        NotificationView().environmentObject({ () -> NotificationCenter in
            let envObj = NotificationCenter.init()
                           return envObj
                       }() )

    }
}



struct AuthorizationDetails: Codable { // or Decodable
  let account: String
  let creditorName: String
  let transaction_amount: Int
  let transaction_id: String
  let type: String
    
}






