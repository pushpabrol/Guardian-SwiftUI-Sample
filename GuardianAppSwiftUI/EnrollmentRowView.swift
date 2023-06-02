//
//  EnrollmentRowView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 6/1/23.
//

import SwiftUI
import Guardian

struct EnrollmentRowView: View {
    @State private var isCopied = false
    @State private var flashingColor: Color = Color.red
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
                    .foregroundColor(countdown < 5 ? flashingColor : .blue)
                    .onReceive(timer) { _ in
                        if countdown < 5 {
                            flashingColor = flashingColor == .red ? .secondary : .red
                        }
                    }
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
                CircularProgressView(progress: timerProgress, countdown: $countdown)
                    .frame(width: 40, height: 40)
            }
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
    
}

struct EnrollmentRowView_Previews: PreviewProvider {
    @State static var enrollment: GuardianState? = GuardianState.init(identifier: "dev_asdad", localIdentifier: UIDevice.current.identifierForVendor!.uuidString, token: "1231231231231231231323", keyTag: "1222", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"), userEmail: "pushp.abrol@gmail.com", enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com")
    static var previews: some View {
        EnrollmentRowView(enrollment: enrollment!)
    }
}