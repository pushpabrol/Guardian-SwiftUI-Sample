import SwiftUI
import Guardian

struct EnrollmentView: View {
    @State private var isCopied = false
    let enrollment: GuardianState
    @EnvironmentObject var refreshManager: EnrollmentListRefreshManager
    @State private var timerProgress: Double = 1.0
    @State private var countdown: Int = 30
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let timerFlash = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var totp: String = "Loading..."
    @State private var flashingColor: Color = Color.red


    
    
    var body: some View {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Group {
                        Text("Domain")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text(enrollment.enrollmentTenantDomain)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("User")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(enrollment.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("Enrollment ID:")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(enrollment.identifier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Text("Local Identifier")
                            .font(.headline)
                            .padding(.horizontal)
                        Text(enrollment.localIdentifier)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    Spacer()
                    HStack {
                        Text("\(totp)")
                            .font(.title)
                            .foregroundColor(countdown < 6 ? flashingColor : .blue)
                            .onReceive(timerFlash) { _ in
                                if countdown < 6 {
                                    flashingColor = flashingColor == .blue ? .red : .blue
                                }
                            }
                        Button(action: {
                            UIPasteboard.general.string = totp.replacingOccurrences(of: " ", with: "")
                            isCopied = true
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                                isCopied = false
                            }
                        }) {
                            Image(systemName: isCopied ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                                .foregroundColor(isCopied ? .blue : .secondary)
                        } .buttonStyle(PlainButtonStyle())
                        Spacer()
                        CircularProgressView(progress: timerProgress, countdown: $countdown)
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                    Button(action: {
                        self.unenroll(enrollment: self.enrollment){
                            DispatchQueue.main.async {
                                refreshManager.shouldRefresh = true // Trigger refresh of EnrollmentListView
                            }

                        }
                    }) {
                        Text("Unenroll")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    

                }
                .padding()
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: -5)
            }
            .onAppear {
                isCopied = false
                self.totp = OTPFunctions.generateTOTP(enrollment: enrollment)
                let steps = OTPFunctions.timeSteps(from: Date().timeIntervalSince1970, period: 30)
                countdown =  (steps + 1)*30 - Int(Date().timeIntervalSince1970)
                timerProgress = 0.03333*Double(countdown)

            }
            .onReceive(timer) { _ in
                self.totp = OTPFunctions.generateTOTP(enrollment: enrollment)
                let steps = OTPFunctions.timeSteps(from: Date().timeIntervalSince1970, period: 30)
                countdown =  (steps + 1)*30 - Int(Date().timeIntervalSince1970)
                timerProgress = 0.03333*Double(countdown)
                if countdown <= 0 {
                    isCopied = false
                    timerProgress = 1.0 - Double(countdown)*(0.03333)
                    countdown = 30 + countdown

                }
            }

        
    }


    
    func unenroll(enrollment: GuardianState?,completion: @escaping () -> Void) -> Void {
        if let enrollment = enrollment {
            let request = Guardian
                .api(forDomain: enrollment.enrollmentTenantDomain)
                .device(forEnrollmentId: enrollment.identifier, token: enrollment.token)
                .delete()
            debugPrint(request)
            request.start { result in
                    switch result {
                    case .failure(let cause):
                        print("Unenroll Error \(cause)")
                        if let cause = cause as? GuardianError {
                            if(cause.code == "device_account_not_found") {
                                //self.enrollment = nil
                                GuardianState.deleteByEnrollmentId(by: enrollment.identifier)
                                
                                completion() // Invoke the completion handler
                                return
                            }
                        }
                    case .success:
                        GuardianState.deleteByEnrollmentId(by: enrollment.identifier)
                        completion() // Invoke the completion handler
                        return
                        //self.enrollment = nil

                    }
                
            }
        }
    }

}



struct EnrollmentView_Previews: PreviewProvider {
    @State static var enrollment: GuardianState? = GuardianState.init(identifier: "dev_asdad", localIdentifier: UIDevice.current.identifierForVendor!.uuidString, token: "1231231231231231231323", keyTag: "1222", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"), userEmail: "pushp.abrol@gmail.com", enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com",enrollmentPIN: "")
    @State static var shouldGoBack = false
    static var previews: some View {
        EnrollmentView(enrollment: enrollment!)
    }
}


