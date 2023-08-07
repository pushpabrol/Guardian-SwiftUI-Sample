# GuardianAppSwiftUI

GuardianAppSwiftUI is a Swift app that utilizes SwiftUI and integrates with the Guardian authentication service using the Auth0 Guardian SDK. The app allows users to receive and handle Guardian authentication notifications, enroll using QR codes, view enrollments, and authenticate using biometric authentication.

## Prerequisites

- Xcode (version X or later)
- iOS deployment target (version X or later)
- CocoaPods & Guardian SDK pod for development ( I am using a modified version to handle showing transaction authorization!)

## Auth0 Configuration


To use this app with Auth0, you need to complete the following steps to configure push notifications for multi-factor authentication (MFA) using Guardian:

1. Follow the steps outlined in the [Configure Push Notifications for Apple using APNs](https://auth0.com/docs/secure/multi-factor-authentication/multi-factor-authentication-factors/configure-push-notifications-for-mfa#configure-push-notifications-for-apple-using-apns) guide in the Auth0 documentation.

2. Set up your Apple Developer account, create an App ID, and configure the necessary certificates and provisioning profiles.

3. Enable Apple Push Notification service (APNs) for your Auth0 tenant.

4. Configure the Auth0 Dashboard with the APNs information, including the `.p8` file and team ID.

5. Configure the MFA factor in the Auth0 Dashboard to use the Guardian service.

6. Ensure that the Auth0 configuration in the app matches your Auth0 tenant domain and other necessary settings.

## Installation

1. Clone the repository:

   ```bash
   $ git clone <repository-url>
   ```

2. Open the project in Xcode.

3. Build and run the app on a simulator or device.

## Usage

1. Launch the app on your device. This will not work on the simulator as it requires notifications!

2. Allow the app to send notifications when prompted.

3. The app registers for remote notifications and handles authentication notifications from the Guardian service.

4. To enroll using a QR code, tap the "Scan QR Code to Enroll" button and scan the QR code.

5. The app processes the enrollment and saves the necessary information locally.

6. Users can view the list of enrollments in the "Enrollments" section.
<img src="./docs/enrollments.PNG" alt="enrollments" height="400"/>

1. Biometric authentication (e.g., Touch ID, Face ID) is used to authenticate the user when the app is opened.

2. If biometric authentication is not available or fails, an alert is displayed.

3. When an authentication request notification is received, the user is presented with an authentication view containing details about the request.
<img src="./docs/notification.PNG" alt="notification" height="400"/>

4.  The user can allow or deny the authentication request using biometric authentication.

5.  Enrollments can be viewed, deleted in the "Enrollments" section.

6.  Users can delete an enrollment by swiping left on an enrollment and tapping the "Delete" button.

7.  The "Enrollments" section is automatically refreshed when an enrollment is deleted or when the app is opened.

8.  In the "Enrollments" section, users can select an enrollment to view additional details.
<img src="./docs/enrollment.PNG" alt="enrollment details" height="400"/>


9.  The details include the domain, user, enrollment ID, local identifier, and the dynamically generated Time-Based One-Time Password (TOTP).

10. The TOTP value is automatically updated every 30 seconds and is displayed with a countdown timer.

11. Users can copy the TOTP value to the clipboard by tapping the copy button next to it.

12. The TOTP value is highlighted with a flashing color when the countdown reaches 5 seconds or less.

13. Users can unenroll by tapping the "Unenroll" button, which removes the enrollment and triggers a refresh of the "Enrollments" section.

## Code Structure

The app consists of the following key components:

- `ContentView`: The main view

 of the app, which displays the enrollment list and handles navigation.
- `EnrollmentListView`: Displays the list of enrollments and allows users to delete enrollments.
- `EnrollmentRowView`: Represents a single row in the enrollment list.
- `EnrollmentView`: Displays the details of an enrollment, including the TOTP value and countdown timer.
- `CircularProgressView`: Custom view for displaying a circular progress indicator with a countdown timer.
- `OTPFunctions`: Helper functions for generating and validating Time-Based One-Time Passwords (TOTP).
- `NotificationView`: Displays the details of an authentication request notification and handles user actions.
- `NotificationCenter`: An environment object used for managing authentication notifications.


## TO DO

Here are some potential enhancements that can be made to the app:

- Improve error handling and provide better feedback to the user in case of authentication or enrollment failures.
- Implement localization for different languages to make the app accessible to a wider audience.

## License

This project is licensed under the [MIT License](LICENSE).

Feel free to use the code and modify it according to your needs.
