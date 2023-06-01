//
//  EnrollmentsListView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 5/28/23.
//

import SwiftUI
import Guardian

struct EnrollmentListView: View {
    @State private var enrollments: [GuardianState] = [] // Replace `Enrollment` with your enrollment data model
    @State private var countdown: Int = 30
    @EnvironmentObject var refreshManager: EnrollmentListRefreshManager
    @State private var shouldGoBack = false
    
    private func loadData() {
        // Add your code to load enrollments here
        enrollments = GuardianState.loadAll()! // Replace with actual data
        let enrollment1 = GuardianState.init(identifier: "test", localIdentifier: "123123", token: "q223312323123", keyTag: "1231232312", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"),userEmail: "pushp.abrol@gmail.com", enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com")
        enrollments.append(enrollment1)
        
    }
        
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            NavigationView {
                List(enrollments, id: \.identifier) { enrollment in
                    NavigationLink(destination: EnrollmentView(enrolled: enrollment)
                        .padding(.vertical,-20)
                        .padding(.bottom,20)){
                            EnrollmentRowView(enrollment: enrollment).environmentObject(refreshManager)}
                }
                
                    .navigationBarTitle("Enrollments", displayMode: .inline)
                    .navigationBarHidden(true)
                    .navigationBarTitleDisplayMode(.large)
                    .onReceive(refreshManager.$shouldRefresh) { shouldRefresh in
                        if shouldRefresh {
                            loadData()
                            refreshManager.shouldRefresh = false // Reset the refresh state
                        }
                    }
            }.onAppear(perform: loadData)
        }
            
        
    }

    struct EnrollmentRowView: View {
        @State private var isCopied = false
        let enrollment: GuardianState
        @State private var timerProgress: Double = 1.0
        @State private var countdown: Int = 30
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        @State private var totp: String = "Loading..."
        var body: some View {
            VStack {
                Text("User: \(enrollment.userEmail)")
                    .font(.caption)
                
                Text("Tenant: \(enrollment.enrollmentTenantDomain.split(separator: ".").map { String($0) }[0])")
                    .font(.caption2)
                
                HStack {
                    Text("\(totp)")
                        .font(.title)
                        .foregroundColor(countdown < 5 ? .red : .blue)
                    Button(action: {
                        UIPasteboard.general.string = totp
                        isCopied = true
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                            isCopied = false
                        }
                    }) {
                        Image(systemName: isCopied ? "doc.on.doc.fill" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : .blue)
                    } .buttonStyle(PlainButtonStyle())
                    Spacer()
                    ListCircularProgress(progress: timerProgress, countdown: $countdown)
                        .frame(width: 40, height: 40)
                }
            }
            
            .onAppear {
                isCopied = false
                self.totp = self.generateTOTP(enrollment: enrollment)
                let steps = timeSteps(from: Date().timeIntervalSince1970, period: 30)
                countdown =  (steps + 1)*30 - Int(Date().timeIntervalSince1970)
                timerProgress = 0.03333*Double(countdown)

            }
            .onReceive(timer) { _ in
                self.totp = self.generateTOTP(enrollment: enrollment)
                let steps = timeSteps(from: Date().timeIntervalSince1970, period: 30)
                countdown =  (steps + 1)*30 - Int(Date().timeIntervalSince1970)
                timerProgress = 0.03333*Double(countdown)
                if countdown <= 0 {
                    isCopied = false
                    timerProgress = 1.0 - Double(countdown)*(0.03333)
                    countdown = 30 + countdown

                }
            }
        }

        func generateTOTP(enrollment: GuardianState) -> String {
                let credential = OTPCredential()
                credential.algorithmName = ((enrollment.otp?.algorithm.rawValue)!)
                credential.base32Secret = enrollment.otp!.base32Secret
                credential.digits = enrollment.otp!.digits
                credential.period = enrollment.otp!.period
                
                guard let algorithm = HMACAlgorithm(rawValue: credential.algorithmName.lowercased()),
                      
                        let generator : Guardian.TOTP = try? Guardian.totp(base32Secret: credential.base32Secret, algorithm: algorithm, digits: credential.digits, period: credential.period) else { return "error" }
                
                let formatter = NumberFormatter()
                formatter.usesGroupingSeparator = true
                formatter.groupingSeparator = " "
                formatter.groupingSize = 3
                formatter.minimumIntegerDigits = 6
                formatter.paddingCharacter = "0"
                
            return String(generator.code())

        }
        
        private func timeSteps(from time: TimeInterval, period: Int) -> Int {
            return Int(time / Double(period))
        }

       
        
        
    }
    
    

    struct ListCircularProgress: View {
        let progress: Double
        @Binding var countdown: Int
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: -90))
                
                Text("\(countdown)")
                    .font(.caption2)
            }
        }
    }
}

struct EnrollmentsListView_Previews: PreviewProvider {
    @State static var refresh: Bool = true
    @StateObject static var refreshManager = EnrollmentListRefreshManager()

    static var previews: some View {
        
        EnrollmentListView().environmentObject(refreshManager)
    }
}



