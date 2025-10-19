//
//  PooSpaceBattleView.swift
//  PooPoo Games Watch App
//
//  Created by Admin on 10/18/25.
//

import SwiftUI

struct PooSpaceBattleView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 15) {
            Text("🚀")
                .font(.system(size: 50))
            
            Text("Poo Space Battle")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: {
                print("Hello World from Poo Space Battle!")
            }) {
                Text("Hello World")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back")
                }
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.brown)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PooSpaceBattleView()
}
