//
//  ContentView.swift
//  PooPoo Games Watch App
//
//  Created by Emilio Montes on 10/18/25.
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
    
    var body: some View {
        NavigationView {
            List(games) { game in
                NavigationLink(destination: destinationView(for: game.name)) {
                    HStack {
                        Image(systemName: game.icon)
                            .foregroundColor(.brown)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Text(game.name)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("💩 Games")
            .listStyle(.carousel)
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
