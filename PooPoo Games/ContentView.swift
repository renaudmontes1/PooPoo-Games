//
//  ContentView.swift
//  PooPoo Games
//
//  Created by  on 10/18/25.
//

import SwiftUI

struct Game: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct ContentView: View {
    let games = [
        Game(name: "Fly Zapper", icon: "ladybug.fill"),
        Game(name: "Yucky Card Sort", icon: "suit.club.fill"),
        Game(name: "Sling-Poo", icon: "figure.disc.sports"),
        Game(name: "Poo Space Battle", icon: "sparkles"),
        Game(name: "Dodge the Yuckies!", icon: "figure.run"),
        Game(name: "Race the Loo", icon: "flag.checkered"),
        Game(name: "Birds on the Wire", icon: "bird.fill"),
        Game(name: "Poo in the Shoe", icon: "shoe.fill"),
        Game(name: "Poo Poo Roo Poo", icon: "pawprint.fill")
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.brown.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("💩 PooPoo Games 💩")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.brown)
                        .padding(.top, 20)
                    
                    Text("Pick a game to play!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(games) { game in
                            NavigationLink(destination: destinationView(for: game.name)) {
                                VStack {
                                    Image(systemName: game.icon)
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 100)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.brown, Color.brown.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(20)
                                        .shadow(radius: 5)
                                    
                                    Text(game.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 40)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    func destinationView(for gameName: String) -> some View {
        switch gameName {
        case "Fly Zapper":
            FlyZapperView()
        case "Yucky Card Sort":
            YuckyCardSortView()
        case "Sling-Poo":
            SlingPooView()
        case "Poo Space Battle":
            PooSpaceBattleView()
        case "Dodge the Yuckies!":
            DodgeTheYuckiesView()
        case "Race the Loo":
            RaceTheLooView()
        case "Birds on the Wire":
            BirdsOnTheWireView()
        case "Poo in the Shoe":
            PooInTheShoeView()
        case "Poo Poo Roo Poo":
            PooPooRooPooView()
        default:
            Text("Game not found")
        }
    }
}

#Preview {
    ContentView()
}
