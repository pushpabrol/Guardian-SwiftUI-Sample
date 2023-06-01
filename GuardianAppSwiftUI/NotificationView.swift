import SwiftUI
import Combine
import Guardian
import JWTDecode

struct NotificationView: View {
    @EnvironmentObject var notificationCenter: NotificationCenter
    @State var browserLabel: String = "Unknown"
    @State var location: Location? = nil
    @State var dateLabel: String = ""
    @State var merchantName: String = ""
    @State var paymentAmount: String = ""
    @State var username: String = ""
    @State var account: String = ""
    @State private var buttonScale: CGFloat = 1.0
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showAllowAlert = false
    @State private var timerAllow: Timer? = nil


    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            
            VStack(spacing: 20) {
                Text("Authentication Request").font(.headline)
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    
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
                    
                    Spacer()

                    HStack(spacing: 50) {
                        Button(action: {
                            self.allowAction(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
                            self.showAllowAlert = true
                            self.timerAllow?.invalidate()
                            self.timerAllow = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
                                self.showAllowAlert = false
                                notificationCenter.authenticationNotification = nil
                            }
                        }) {
                            Text("Allow")
                                .font(.headline)
                                .padding()
                                .frame(width: 130, height: 50)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .scaleEffect(buttonScale)
                        }

                        Button(action: {
                            self.denyAction(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
                        }) {
                            Text("Deny")
                                .font(.headline)
                                .padding()
                                .frame(width: 130, height: 50)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .scaleEffect(buttonScale)
                        }
                    }
                    .padding(.horizontal)

                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .shadow(radius: 10)


            }
            .padding()
            .onAppear {
                self.loadData(enrollment: GuardianState.loadByEnrollmentId(by: notificationCenter.authenticationNotification!.enrollmentId))
            }

            if showAllowAlert {
                Text("Access Granted. Continue at \(self.merchantName) to complete your transaction!")
                    .font(.title)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 2.0)))
            }
        }
        .onReceive(timer) { _ in
            self.buttonScale = self.buttonScale == 1.0 ? 1.1 : 1.0
        }
    }


    func loadData(enrollment: GuardianState?) {
        guard let notification = notificationCenter.authenticationNotification, let _ = enrollment else {
            return
        }
        browserLabel = notification.source?.browser?.name ?? "Unknown"
        location = notification.location!
        dateLabel = "\(notification.startedAt.formatted(date: .abbreviated, time: Date.FormatStyle.TimeStyle.standard))"
        let jwt = try! decode(jwt: notification.transactionToken)
        
        self.username = String(jwt["sub"].string!.split(separator: "|")[1])
        
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
            .reject(notification: notification)
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


struct AuthorizationDetails: Codable { // or Decodable
  let account: String
  let creditorName: String
  let transaction_amount: Int
  let transaction_id: String
  let type: String
    
}
