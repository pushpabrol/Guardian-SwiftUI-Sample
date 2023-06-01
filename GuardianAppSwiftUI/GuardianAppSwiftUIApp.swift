
import SwiftUI
import UserNotifications
import os
import Guardian
import QRCodeReader

class AppDelegate: NSObject, UIApplicationDelegate {
    //static let guardianDomain = "sca-poc-cancun.guardian.us.auth0.com"
    static var pushToken: String? = nil
    var notificationManager: NotificationCenter?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            
        let token = deviceToken.reduce(String(), {$0 + String(format: "%02X", $1)})
        AppDelegate.pushToken = token
           print("\(token)")
       }
       
       func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
           print(error.localizedDescription)
       }
    
    
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        
        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")
        
        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let qrCodePath = components.path,
            let params = components.queryItems else {
                print("Invalid QR Code or missing")
                return false
        }
        
        if let barcodeUri = params.first(where: { $0.name == "barcode_uri" })?.value {
            print("qrCodePath = \(qrCodePath)")
            print("barcodeUri = \(barcodeUri)")
            
            let content = UNMutableNotificationContent()
            content.title = "BARCODE_URI_RECEIVED"
            content.subtitle = qrCodePath
            content.body = barcodeUri
            
            let request = UNNotificationRequest.init(identifier: "localNotificatoin", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

            return true
        } else {
            print("barcodeUri missing")
            return false
        }
    }

}

extension AppDelegate {
    static var state: GuardianState? {
        get {
            return GuardianState.load()
        }
        set {
            if newValue == nil {
                GuardianState.delete()
            } else {
                try? newValue?.save()
            }
        }
    }
    
    static func getByEnrollmentId(enrollmentId: String) -> GuardianState? {
        return GuardianState.loadByEnrollmentId(by: enrollmentId)
    }
    
    static func saveEnrollmentById(enrollment: GuardianState) -> Void {
        try! enrollment.saveByEnrollmentId()
    }
}



@main
struct GuardianAppSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var notificationCenter = NotificationCenter()
    

    var body: some Scene {
        WindowGroup {
            
            ContentView().environmentObject(notificationCenter).background(  LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.blue.opacity(0.10)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all))
        }
    }
}

struct GuardianAppSwiftUIApp_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(NotificationCenter())
    }
}


public class NotificationCenter: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var authenticationNotification : Guardian.Notification? = nil

    override init() {
        super.init()
        let guardianCategory = Guardian.AuthenticationCategory.default
        // Set up guardian notifications actions
        let acceptAction = UNNotificationAction(
            identifier: guardianCategory.allow.identifier,
            title: NSLocalizedString("Allow", comment: "Accept Guardian authentication request"),
            options: [.authenticationRequired] // Always request local AuthN
        )
        let rejectAction = UNNotificationAction(
            identifier: guardianCategory.reject.identifier,
            title: NSLocalizedString("Deny", comment: "Reject Guardian authentication request"),
            options: [.destructive, .authenticationRequired] // Always request local AuthN
        )

        // Set up guardian notification category
        let category = UNNotificationCategory(
            identifier: guardianCategory.identifier,
            actions: [acceptAction, rejectAction],
            intentIdentifiers: [],
            options: [])

        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound]) { granted, error in
            guard granted else {
                return print("Permission not granted")
            }
            print("Permission granted")
            
            if let error = error {
                return print("failed with error \(error)")
            }

            // Register guardian notification category
            UNUserNotificationCenter.current().setNotificationCategories([category])
            // Check AuthZ status to trigger remote notification registration
            UNUserNotificationCenter.current().getNotificationSettings() { settings in
                guard settings.authorizationStatus == .authorized else {
                    return print("not authorized to use notifications")
                }
                
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //let content = notification.request.content
        //let identifier = notification.request.identifier
        let userInfo = notification.request.content.userInfo
        print(userInfo)

        if let notification = Guardian.notification(from: userInfo) {
            show(notification: notification)
        }
        completionHandler([]) //Avoid displaying iOS UI when app in foreground
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            //let content = response.notification.request.content
        
        let identifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo

        // when the app has been activated by the user selecting an action from a remote notification
        print("identifier: \(identifier), userInfo: \(userInfo)")

        if let notification = Guardian.notification(from: userInfo),
           let enrollment = AppDelegate.getByEnrollmentId(enrollmentId: notification.enrollmentId)
        {
            if UNNotificationDefaultActionIdentifier == identifier { // App opened from notification
                show(notification: notification)
                completionHandler()
            } else { // Guardian allow/reject action
                Guardian
                    .authentication(forDomain: enrollment.enrollmentTenantDomain, device: enrollment)
                    .handleAction(withIdentifier: identifier, notification: notification)
                    .start {
                        _ in completionHandler()
                        
                    }
            }
        } else { // Nothing we can handle, just not known notification
            completionHandler()
        }
            completionHandler()
        }
    
    
    private func show(notification: Guardian.Notification) {
        print(notification)

        authenticationNotification = notification
    }
}



