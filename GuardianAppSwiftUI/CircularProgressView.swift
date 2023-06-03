//
//  CircularProgressView.swift
//  GuardianAppSwiftUI
//
//  Created by Pushp Abrol on 6/1/23.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    @Binding var countdown: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .opacity(0.8)
                .foregroundColor(.secondary)
                
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: -90))
            
            Text("\(countdown)")
                .font(.caption2)
        }
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    @State static var countdown = 22
    

    static var previews: some View {
        CircularProgressView(progress: 0.75, countdown:$countdown )
    }
}
