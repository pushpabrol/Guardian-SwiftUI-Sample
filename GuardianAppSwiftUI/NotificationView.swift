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
    @State var account: String = ""
    @State private var buttonScale: CGFloat = 1.0
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var showAllowAlert = false
    @State private var timerAllow: Timer? = nil


    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, Color(UIColor.systemGray4)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(browserLabel)
                        .font(.headline)
                        .padding(.horizontal)

                    Text(location?.name! ?? "UnKnown")
                        .font(.subheadline)
                        .padding(.horizontal)

                    Text(dateLabel)
                        .font(.caption)
                        .padding(.horizontal)

                    Text("\(merchantName) is requesting a payment of \(paymentAmount) from your account: \(account)")
                        .font(.headline)
                        .padding(.horizontal)

                }
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .shadow(radius: 10)

                Spacer()

                HStack(spacing: 50) {
                    Button(action: {
                        self.allowAction()
                        self.showAllowAlert = true
                        self.timerAllow?.invalidate()
                        self.timerAllow = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
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
                    }

                    Button(action: {
                        self.denyAction()
                    }) {
                        Text("Deny")
                            .font(.headline)
                            .padding()
                            .frame(width: 130, height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear {
                self.loadData()
            }

            if showAllowAlert {
                Text("Access Granted")
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


    func loadData() {
        guard let notification = notificationCenter.authenticationNotification, let _ = AppDelegate.state else {
            return
        }
        browserLabel = notification.source?.browser?.name ?? "Unknown"
        location = notification.location!
        dateLabel = "\(notification.startedAt)"
        let jwt = try! decode(jwt: notification.transactionToken)
        
        let userId = jwt["sub"].string!.split(separator: "|")[1]
        
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

    func allowAction() {
        guard let notification = notificationCenter.authenticationNotification, let enrollment = AppDelegate.state else {
            notificationCenter.authenticationNotification = nil
            return
        }
        let request = Guardian
            .authentication(forDomain: AppDelegate.guardianDomain, device: enrollment)
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

    func denyAction() {
        guard let notification = notificationCenter.authenticationNotification, let enrollment = AppDelegate.state else {
            notificationCenter.authenticationNotification = nil
            return
        }
        let request = Guardian
            .authentication(forDomain: AppDelegate.guardianDomain, device: enrollment)
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
