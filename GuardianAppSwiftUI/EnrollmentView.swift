import SwiftUI
import Guardian

struct EnrollmentView: View {
    let enrolled: GuardianState
    @EnvironmentObject var refreshManager: EnrollmentListRefreshManager

    
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Domain")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(enrolled.enrollmentTenantDomain)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Text("User")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(enrolled.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Text("Enrollment ID:")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(enrolled.identifier)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Text("Local Identifier")
                        .font(.headline)
                        .padding(.horizontal)
                    Text(enrolled.localIdentifier)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        self.unenroll(enrollment: self.enrolled){
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
                    .padding(.horizontal)

                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: -5)


            }
            .padding()
            .onAppear{
                
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
                                //self.enrolled = nil
                                GuardianState.deleteByEnrollmentId(by: enrollment.identifier)
                                
                                completion() // Invoke the completion handler
                                return
                            }
                        }
                    case .success:
                        GuardianState.deleteByEnrollmentId(by: enrollment.identifier)
                        completion() // Invoke the completion handler
                        return
                        //self.enrolled = nil

                    }
                
            }
        }
    }

}



struct EnrollmentView_Previews: PreviewProvider {
    @State static var enrolled: GuardianState? = GuardianState.init(identifier: "dev_asdad", localIdentifier: UIDevice.current.identifierForVendor!.uuidString, token: "1231231231231231231323", keyTag: "1222", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"), userEmail: "pushp.abrol@gmail.com", enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com")
    @State static var shouldGoBack = false
    static var previews: some View {
        EnrollmentView(enrolled: enrolled!)
    }
}


