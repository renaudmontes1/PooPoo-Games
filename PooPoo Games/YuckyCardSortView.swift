//
//  YuckyCardSortView.swift
//  PooPoo Games
//
//  Created by Rens Team on 10/18/25.
//

import SwiftUI
import Combine

// Card model
struct YuckyCard: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var isMatched = false
    var isFaceUp = false
}

// Game state
class CardGameState: ObservableObject {
    enum GamePhase {
        case welcome
        case playing
        case levelComplete
        case gameComplete
    }
    
    @Published var cards: [YuckyCard] = []
    @Published var currentLevel: Int = 1
    @Published var gamePhase: GamePhase = .welcome
    @Published var firstFlippedIndex: Int?
    @Published var isCheckingMatch = false
    
    let yuckyEmojis = ["💩", "🤮", "🦠", "🧻", "🪰", "🪳", "🕷️", "🦟", "🐛", "🧟", "👻", "💀", "🤢", "🤧", "🩸", "🦴"]
    let maxLevel = 10
    
    func startGame() {
        currentLevel = 1
        gamePhase = .playing
        setupLevel()
    }
    
    func setupLevel() {
        // Calculate number of pairs: level 1 = 2 pairs (4 cards), level 2 = 4 pairs (8 cards), etc.
        let numberOfPairs = min(2 * currentLevel, yuckyEmojis.count)
        let selectedEmojis = Array(yuckyEmojis.shuffled().prefix(numberOfPairs))
        
        // Create pairs
        var newCards: [YuckyCard] = []
        for emoji in selectedEmojis {
            newCards.append(YuckyCard(emoji: emoji))
            newCards.append(YuckyCard(emoji: emoji))
        }
        
        cards = newCards.shuffled()
        firstFlippedIndex = nil
        isCheckingMatch = false
    }
    
    func flipCard(at index: Int) {
        guard !isCheckingMatch,
              !cards[index].isMatched,
              !cards[index].isFaceUp else { return }
        
        cards[index].isFaceUp = true
        
        if let firstIndex = firstFlippedIndex {
            // Second card flipped
            isCheckingMatch = true
            
            if cards[firstIndex].emoji == cards[index].emoji {
                // Match found
                cards[firstIndex].isMatched = true
                cards[index].isMatched = true
                firstFlippedIndex = nil
                isCheckingMatch = false
                
                checkLevelComplete()
            } else {
                // No match - flip back after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.cards[firstIndex].isFaceUp = false
                    self.cards[index].isFaceUp = false
                    self.firstFlippedIndex = nil
                    self.isCheckingMatch = false
                }
            }
        } else {
            // First card flipped
            firstFlippedIndex = index
        }
    }
    
    func checkLevelComplete() {
        if cards.allSatisfy({ $0.isMatched }) {
            // Wait 1 second before showing level complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if self.currentLevel >= self.maxLevel {
                    self.gamePhase = .gameComplete
                } else {
                    self.gamePhase = .levelComplete
                }
            }
        }
    }
    
    func nextLevel() {
        currentLevel += 1
        gamePhase = .playing
        setupLevel()
    }
}

struct YuckyCardSortView: View {
    @StateObject private var gameState = CardGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.purple.opacity(0.3)
                .ignoresSafeArea()
            
            if gameState.gamePhase == .welcome {
                // Welcome Screen
                VStack(spacing: 30) {
                    Text("🤢 Yucky Card Sort 🤮")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.brown)
                        .multilineTextAlignment(.center)
                    
                    Text("Match the disgusting pairs!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Start with 4 cards\nDouble each level up to 10!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Start Game") {
                        gameState.startGame()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    
                    Button("Home") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brown)
                    .cornerRadius(10)
                }
                .padding()
            } else if gameState.gamePhase == .levelComplete {
                // Level Complete Screen
                VStack(spacing: 30) {
                    Text("🎉 Level \(gameState.currentLevel) Complete! 🎉")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                    
                    Button("Next Level") {
                        gameState.nextLevel()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    
                    Button("Home") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brown)
                    .cornerRadius(10)
                }
                .padding()
            } else if gameState.gamePhase == .gameComplete {
                // Game Complete Screen
                VStack(spacing: 30) {
                    Text("🏆 You Won! 🏆")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("Completed all 10 levels!")
                        .font(.title2)                        .foregroundColor(.white)
                    
                    Button("Play Again") {
                        gameState.startGame()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(Color.green)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    
                    Button("Home") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.brown)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                // Playing Screen
                VStack {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                                .padding(12)
                                .background(Color.brown.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Level \(gameState.currentLevel)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.brown)
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 48, height: 48)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Card Grid
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnsForLevel(gameState.currentLevel))
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(gameState.cards.enumerated()), id: \.element.id) { index, card in
                                CardView(card: card)
                                    .aspectRatio(0.7, contentMode: .fit)
                                    .onTapGesture {
                                        gameState.flipCard(at: index)
                                    }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func columnsForLevel(_ level: Int) -> Int {
        let totalCards = 2 * 2 * level
        if totalCards <= 8 { return 4 }
        if totalCards <= 16 { return 4 }
        if totalCards <= 32 { return 6 }
        return 8
    }
}

struct CardView: View {
    let card: YuckyCard
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.isMatched ? Color.green.opacity(0.3) : Color.white)
                    .overlay(
                        Text(card.emoji)
                            .font(.system(size: 40))
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brown, Color.brown.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text("💩")
                            .font(.system(size: 30))
                            .opacity(0.5)
                    )
            }
        }
        .shadow(radius: 3)
    }
}

#Preview {
    YuckyCardSortView()
}
