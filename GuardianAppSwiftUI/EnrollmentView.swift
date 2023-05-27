import SwiftUI
import Guardian

struct EnrollmentView: View {
    @State private var enrollmentId: String = ""
    @State private var otpSecret: String = ""
    @State private var totp: String = "Loading..."
    @State private var timerProgress: Double = 1.0
    @Binding var enrolled: GuardianState?
    @State private var localIdentifier: String = ""
    @State private var countdown: Int = 30
    
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enrollment ID: \(enrollmentId)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("OTP Secret: \(otpSecret)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("Local Identifier: \(localIdentifier)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    
                    HStack {
                        Text("TOTP: \(totp)")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        Spacer()
                        CircularProgress(progress: timerProgress, countdown: $countdown).frame(width: 40, height: 40).padding(.horizontal)

                    }
                    
                }
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.8))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: -5)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {

                    
                    Button(action: {
                        self.unenroll()
                    }) {
                        Text("Unenroll")
                            .font(.headline)
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .onAppear(perform: loadData)
            .onReceive(timer) { _ in
                self.timerProgress -= 0.03333
                self.countdown -= 1
                if self.timerProgress <= 0 {
                    self.totp = self.generateTOTP() // Call your TOTP generation method
                    self.timerProgress = 1.0
                    self.countdown = 30
                }
            }
        }
    }

    func loadData() {
        // Fetch your data here
        // This is just placeholder data
        if let enrollment = AppDelegate.state {
            self.enrollmentId = enrollment.identifier
            self.otpSecret = enrollment.otp!.base32Secret
            self.totp = generateTOTP()
            self.localIdentifier = enrollment.localIdentifier
            
            
        }

    }

    func unenroll() {
        if let enrollment = AppDelegate.state {
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
                                self.enrolled = nil
                                AppDelegate.state = nil

                            }
                        }
                    case .success:
                        AppDelegate.state = nil
                        self.enrolled = nil

                    }
                
            }
        }
    }
    
    func generateTOTP() -> String {
        if let enrollment = AppDelegate.state {
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
        return "error"
    }
}


struct CircularProgress: View {
    var progress: Double
    @Binding var countdown: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(Color.black)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .bevel))
                .foregroundColor(Color.white)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
                
            Text("\(countdown)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.black)
        }
    }
}


