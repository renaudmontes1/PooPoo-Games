//
//  FlyZapperView.swift
//  PooPoo Games Watch App
//
//  Created by Admin on 10/18/25.
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
        CGPoint(x: screenBounds.midX, y: screenBounds.maxY - 10)  // Moved closer to bottom
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
            x: CGFloat.random(in: 20...(screenBounds.width - 20)),
            y: 20
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
        let targetX = poopPosition.x + CGFloat.random(in: -50...50)
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
        let collisionDistance: CGFloat = 25  // Slightly smaller collision area
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                if gameState.gamePhase == .about {
                    // About Screen
                    VStack(spacing: 15) {
                        Text("About")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Created by PooPooGames")
                            .foregroundColor(.white)
                        
                        Link("www.poopoogames.com", destination: URL(string: "http://www.poopoogames.com")!)
                            .foregroundColor(.blue)
                        
                        Button("Back") {
                            gameState.hideAbout()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if gameState.gamePhase == .welcome {
                    // Welcome Screen
                    VStack(spacing: 0) {
                        // Top row with info button
                        HStack {
                            Button(action: { gameState.showAbout() }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                            .padding(.leading, 10)
                            Spacer()
                        }
                        .frame(height: 44)
                        
                        // Center content with proper spacing
                        Spacer()
                        VStack(spacing: 15) {
                            Text("🪰 Fly Zapper! 💩")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Tap the fly before it reaches the poop!")
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Start Game") {
                                gameState.startGame()
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                    }
                } else {
                    // Score
                    Text("Score: \(gameState.score)")
                        .foregroundColor(.white)
                        .position(x: geometry.size.width / 2, y: 20)
                    
                    // Fly
                    Text("🪰")
                        .font(.system(size: 30))
                        .rotationEffect(Angle(radians: gameState.flyAngle))
                        .position(gameState.flyPosition)
                    
                    // Poop
                    Text("💩")
                        .font(.system(size: 40))
                        .position(gameState.poopPosition)
                    
                    // Game Over overlay
                    if gameState.gamePhase == .gameOver {
                        VStack {
                            Text("Game Over!")
                                .font(.title2)
                                .foregroundColor(.red)
                            Button("Play Again") {
                                gameState.startGame()
                            }
                            .buttonStyle(.bordered)
                        }
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
                        let location = value.location
                        // Check if we hit the fly
                        let hitDistance: CGFloat = 30
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
