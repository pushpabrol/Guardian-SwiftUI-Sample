//
//  OTPFunctions.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 6/1/23.
//

import Foundation
import Guardian


class OTPFunctions {
    
    static func generateTOTP(enrollment: GuardianState) -> String {
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
            
        return String(generator.stringCode(formatter: formatter))

    }
    
    static func timeSteps(from time: TimeInterval, period: Int) -> Int {
        return Int(time / Double(period))
    }
}
