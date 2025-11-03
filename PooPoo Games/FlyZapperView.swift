//
//  FlyZapperView.swift
//  PooPoo Games
//
//  Created by Emilio Montes on 10/18/25.
//

import SwiftUI
import Combine

// Game state to manage the game logic
class GameState: ObservableObject {
    enum GamePhase {
        case welcome
        case playing
        case gameOver
        case about
    }
    
    @Published var flyPosition: CGPoint = .zero
    @Published var flySpeed: Double = 100.0  // Points per second
    @Published var score: Int = 0
    @Published var gamePhase: GamePhase = .welcome
    @Published var flyAngle: Double = 0  // For rotation animation
    
    // Screen bounds for calculations
    var screenBounds: CGRect = .zero
    
    // Position for the poop (bottom center)
    var poopPosition: CGPoint {
        CGPoint(x: screenBounds.midX, y: screenBounds.maxY - 50)
    }
    
    // Timer for fly movement
    private var moveTimer: Timer?
    
    // Initialize the game
    func startGame() {
        gamePhase = .playing
        score = 0
        flySpeed = 100.0
        resetFlyPosition()
        startFlyMovement()
    }
    
    // Reset fly to random top position
    func resetFlyPosition() {
        flyPosition = CGPoint(
            x: CGFloat.random(in: 40...(screenBounds.width - 40)),
            y: 40
        )
    }
    
    // Start fly movement timer
    private func startFlyMovement() {
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.updateFlyPosition()
        }
    }
    
    // Update fly position with random movement
    private func updateFlyPosition() {
        let targetX = poopPosition.x + CGFloat.random(in: -80...80)
        let targetY = poopPosition.y
        
        let dx = targetX - flyPosition.x
        let dy = targetY - flyPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let speedPerFrame = flySpeed / 60
        let moveFactor = speedPerFrame / distance
        
        flyPosition.x += dx * moveFactor
        flyPosition.y += dy * moveFactor
        
        // Rotate fly based on movement
        flyAngle = atan2(dy, dx)
        
        // Check for collision with poop
        let collisionDistance: CGFloat = 40
        if distance < collisionDistance {
            gameOver()
        }
    }
    
    // Handle successful zap
    func zapFly() {
        score += 1
        flySpeed += 20  // Increase speed
        resetFlyPosition()
    }
    
    // Handle game over
    private func gameOver() {
        gamePhase = .gameOver
        moveTimer?.invalidate()
        moveTimer = nil
    }
    
    func showAbout() {
        moveTimer?.invalidate()
        moveTimer = nil
        gamePhase = .about
    }
    
    func hideAbout() {
        gamePhase = .welcome
    }
}

struct FlyZapperView: View {
    @StateObject private var gameState = GameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                if gameState.gamePhase == .about {
                    // About Screen
                    VStack(spacing: 20) {
                        Text("About")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Created by PooPooGames")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Link("www.poopoogames.com", destination: URL(string: "http://www.poopoogames.com")!)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Button("Back") {
                            gameState.hideAbout()
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.brown)
                        .cornerRadius(10)
                    }
                } else if gameState.gamePhase == .welcome {
                    // Welcome Screen
                    VStack(spacing: 0) {
                        // Top row with info button
                        HStack {
                            Button(action: { gameState.showAbout() }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30))
                            }
                            .padding(.leading, 20)
                            .padding(.top, 20)
                            Spacer()
                        }
                        
                        // Center content with proper spacing
                        Spacer()
                        VStack(spacing: 30) {
                            Text("🪰 Fly Zapper! 💩")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Tap the fly before it reaches the poop!")
                                .font(.title3)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
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
                        }
                        Spacer()
                    }
                } else {
                    // Score
                    Text("Score: \(gameState.score)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .position(x: geometry.size.width / 2, y: 50)
                    
                    // Back button in top left during gameplay
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding(12)
                            .background(Color.brown.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .position(x: 40, y: 50)
                    
                    // Fly
                    Text("🪰")
                        .font(.system(size: 60))
                        .rotationEffect(Angle(radians: gameState.flyAngle))
                        .position(gameState.flyPosition)
                    
                    // Poop
                    Text("💩")
                        .font(.system(size: 80))
                        .position(gameState.poopPosition)
                    
                    // Game Over overlay
                    if gameState.gamePhase == .gameOver {
                        VStack(spacing: 30) {
                            Text("Game Over!")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("Final Score: \(gameState.score)")
                                .font(.title)
                                .foregroundColor(.white)
                            
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
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 250, height: 60)
                            .background(Color.brown)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                    }
                }
            }
            .onAppear {
                gameState.screenBounds = geometry.frame(in: .local)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // Only allow tapping during active gameplay
                        guard gameState.gamePhase == .playing else { return }
                        
                        let location = value.location
                        // Check if we hit the fly
                        let hitDistance: CGFloat = 50
                        let dx = location.x - gameState.flyPosition.x
                        let dy = location.y - gameState.flyPosition.y
                        let distance = sqrt(dx * dx + dy * dy)
                
                        if distance < hitDistance {
                            gameState.zapFly()
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    FlyZapperView()
}
