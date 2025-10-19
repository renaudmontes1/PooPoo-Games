//
//  BirdsOnTheWireView.swift
//  PooPoo Games
//
//  Created by Admin on 10/18/25.
//

import SwiftUI

struct BirdsOnTheWireView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.cyan.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("🐦 Birds on the Wire 🐦")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                
                Spacer()
                
                Button(action: {
                    print("Hello World from Birds on the Wire!")
                }) {
                    Text("Start Game")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.green)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back to Home")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brown)
                    .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    BirdsOnTheWireView()
}
