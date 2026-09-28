//
//  CustomTextField.swift
//  QuickBites
//
//  Created by Karakat Tursynbayeva on 9/27/26.
//

import SwiftUI

extension Color {
    static let darkBackground = Color(red: 0.05, green: 0.07, blue: 0.11)
    static let darkCard = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let darkCardBorder = Color(red: 0.16, green: 0.22, blue: 0.30)
    static let accentCyan = Color(red: 0.18, green: 0.74, blue: 0.96)
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.darkCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.darkCardBorder, lineWidth: 1)
        )
    }
}
