//
//  YuckyCardSortView.swift
//  PooPoo Games Watch App
//
//  Created by Admin on 10/18/25.
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
    
    let yuckyEmojis = ["💩", "🤮", "🦠", "🧻", "🪰", "🪳", "🕷️", "🦟", "🐛", "🧟"]
    let maxLevel = 1000
    
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
            if currentLevel >= maxLevel {
                gamePhase = .gameComplete
            } else {
                gamePhase = .levelComplete
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
                ScrollView {
                    VStack(spacing: 15) {
                        Text("🤢 Yucky Card Sort 🤮")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                        
                        Text("Match the disgusting pairs!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Start Game") {
                            gameState.startGame()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Home") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brown)
                    }
                    .padding()
                }
            } else if gameState.gamePhase == .levelComplete {
                // Level Complete Screen
                VStack(spacing: 15) {
                    Text("🎉 Level \(gameState.currentLevel) Complete!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                    
                    Button("Next Level") {
                        gameState.nextLevel()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Home") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brown)
                }
                .padding()
            } else if gameState.gamePhase == .gameComplete {
                // Game Complete Screen
                VStack(spacing: 15) {
                    Text("🏆 You Won!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("All 1000 levels!")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Button("Play Again") {
                        gameState.startGame()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Home") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brown)
                }
                .padding()
            } else {
                // Playing Screen
                VStack(spacing: 5) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        }
                        
                        Spacer()
                        
                        Text("Lv \(gameState.currentLevel)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.brown)
                        
                        Spacer()
                        
                        Text("")
                            .frame(width: 16)
                    }
                    .padding(.horizontal, 5)
                    
                    // Card Grid
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 2)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(Array(gameState.cards.enumerated()), id: \.element.id) { index, card in
                                WatchCardView(card: card)
                                    .aspectRatio(0.7, contentMode: .fit)
                                    .onTapGesture {
                                        gameState.flipCard(at: index)
                                    }
                            }
                        }
                        .padding(5)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct WatchCardView: View {
    let card: YuckyCard
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.isMatched ? Color.green.opacity(0.3) : Color.white)
                    .overlay(
                        Text(card.emoji)
                            .font(.system(size: 24))
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.brown, Color.brown.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text("💩")
                            .font(.system(size: 18))
                            .opacity(0.5)
                    )
            }
        }
        .shadow(radius: 2)
    }
}

#Preview {
    YuckyCardSortView()
}
