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
 // Sample enrollment, can be uncommented for testing!
//        let enrollment1 = GuardianState.init(identifier: "test", localIdentifier: "123123", token: "q223312323123", keyTag: "1231232312", otp: OTPParameters(base32Secret: "3SLSWZPQQBB7WBRYDAQZ5J77W5D7I6GU"),userEmail: "pushp.abrol@gmail.com", enrollmentTenantDomain: "sca-poc-cancun.guardian.us.auth0.com")
//        enrollments.append(enrollment1)
        
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
        
    var body: some View {
            
            NavigationView {
                List {
                    ForEach(enrollments, id: \.identifier) { enrollment in
                        NavigationLink(destination: EnrollmentView(enrollment: enrollment)
                                        .padding(.bottom, 20)) {
                            EnrollmentRowView(enrollment: enrollment)
                                .environmentObject(refreshManager)
                                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let enrollmentSelected = enrollments[index]
                            self.unenroll(enrollment: enrollmentSelected){
                                print("unenrolled")
                                DispatchQueue.main.async {
                                    refreshManager.shouldRefresh = true // Trigger refresh of EnrollmentListView
                                }

                            }
                           
                        }
                    }
                }
                .background(.clear)
                .scrollContentBackground(.hidden)
                .navigationBarTitle("Enrollments", displayMode: .inline)
                             .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.large)
                .onReceive(refreshManager.$shouldRefresh) { shouldRefresh in
                    if shouldRefresh {
                        loadData()
                        refreshManager.shouldRefresh = false // Reset the refresh state
                    }
                }
            }
            .onAppear(perform: loadData)
        
    }
}

struct EnrollmentsListView_Previews: PreviewProvider {
    @State static var refresh: Bool = true
    @StateObject static var refreshManager = EnrollmentListRefreshManager()
    static var previews: some View {
        EnrollmentListView().environmentObject(refreshManager)
    }
}



