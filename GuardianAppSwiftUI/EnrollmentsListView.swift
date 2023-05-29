//
//  EnrollmentsListView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 5/28/23.
//

import SwiftUI
import Guardian

struct EnrollmentListView: View {
    @State private var timerProgress: Double = 1.0
    @State private var enrollments: [GuardianState] = [] // Replace `Enrollment` with your enrollment data model
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var countdown: Int = 30

    private func loadData() {
        // Add your code to load enrollments here
        enrollments = [GuardianState]() // Replace with actual data
        
        // Example enrollments
        let enrollment1 = GuardianState.init(identifier: "dev_asdad", localIdentifier: UIDevice.current.identifierForVendor!.uuidString, token: "asdads", keyTag: "123", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU") )
        let enrollment2 = GuardianState.init(identifier: "push_asdad", localIdentifier: UIDevice.current.identifierForVendor!.uuidString, token: "assdasdsadads", keyTag: "155", otp: OTPParameters(base32Secret: "WHUCR5L6IVTCWNIUY6R3EALRT2SCOCGA") )
        
        
        enrollments.append(enrollment1)
        enrollments.append(enrollment2)
    }
    
    
    func unenroll(enrollment: GuardianState) {
            let request = Guardian
                .api(forDomain: AppDelegate.guardianDomain)
                .device(forEnrollmentId: enrollment.identifier, token: enrollment.token)
                .delete()
            debugPrint(request)
            request.start { result in
                    switch result {
                    case .failure(let cause):
                        print("Unenroll Error \(cause)")
                        if let cause = cause as? GuardianError {
                            if(cause.code == "device_account_not_found") {
                                GuardianState.deleteByEnrollmentId(by: enrollment.identifier)

                            }
                        }
                    case .success:
                        GuardianState.deleteByEnrollmentId(by: enrollment.identifier)

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

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            List(enrollments, id: \.identifier) { enrollment in
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enrollment ID: \(enrollment.identifier)")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("OTP Secret: secret")
                            .font(.headline)
                            .padding(.horizontal)

                        Text("Local Identifier: \(enrollment.localIdentifier)")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack {
                            Text("TOTP: \(self.generateTOTP(enrollment: enrollment))") // Add the corresponding property to your `Enrollment` model
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            Spacer()
                            CircularProgress(progress: timerProgress, countdown: $countdown)
                                .frame(width: 40, height: 40)
                                .padding(.horizontal)

                        }
                    }
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                    .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: -5)
                }
                .padding()
                .onReceive(timer) { _ in
                    self.timerProgress -= 0.03333
                    self.countdown -= 1
                    if self.timerProgress <= 0 {
                        self.timerProgress = 1.0
                        self.countdown = 30
                    }
                }
            } .onAppear(perform: loadData)
        }
    }
}

struct EnrollmentsListView_Previews: PreviewProvider {
    static var previews: some View {
        EnrollmentListView()
    }
}



