//
//  YuckyCardSortView.swift
//  PooPoo Games Watch App
//
//  Created by Admin on 10/18/25.
//

import SwiftUI

struct YuckyCardSortView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 15) {
            Text("🃏")
                .font(.system(size: 50))
            
            Text("Yucky Card Sort")
                .font(.headline)
                .foregroundColor(.brown)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: {
                print("Hello World from Yucky Card Sort!")
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    YuckyCardSortView()
}
