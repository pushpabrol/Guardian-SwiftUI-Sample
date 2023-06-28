import SwiftUI
import Guardian
import PasscodeField

public struct PINVerificationView: View {
    @Binding var pin: String
    var enrollment: GuardianState
    var onPINVerification: (Bool) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingAlert: Bool = false
    @State private var isPresentingPasscode = true

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Spacer()
                    Image("a0black")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32) // Adjust the size as needed
                        .padding(.horizontal)
                }
                .padding()

                VStack {
                    
                Text("Verify with your PIN to continue!")
                    .font(.headline)
                    .padding(.horizontal)

                    PasscodeField("Enter PIN") { digits,action  in
                        print(pin);
                        print(digits.concat)
                        let isPINVerified = (digits.concat == enrollment.enrollmentPIN)
                        if isPINVerified {
                            withAnimation {
                                isPresentingPasscode = false
                            }
                            action(true)
                            onPINVerification(isPINVerified)
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            withAnimation {
                                isShowingAlert = true
                            }
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding()
            }
        }.alert("PIN did not match", isPresented: $isShowingAlert) {
            Button("Retry") { isShowingAlert = false }
            Button("Quit") { isShowingAlert = false }
        }
        .navigationBarTitle("Create PIN")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.title)
                .foregroundColor(.blue)
        })
    }
                    
            

}

struct PINVerificationView_Previews: PreviewProvider {
    @State static var enrollment: GuardianState? = GuardianState(
        identifier: "dev_asdad",
        localIdentifier: UIDevice.current.identifierForVendor!.uuidString,
        token: "1231231231231231231323",
        keyTag: "1222",
        otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"),
        userEmail: "pushp.abrol@gmail.com",
        enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com",
        enrollmentPIN: "0000"
    )
    
    @State static var isShowingAlert: Bool = false

    static var previews: some View {
        PINVerificationView(
            pin: .constant(""),
            enrollment: enrollment!,
            onPINVerification: { _ in }
        )
    }
}

