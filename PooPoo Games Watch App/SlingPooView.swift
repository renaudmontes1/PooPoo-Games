//
//  SlingPooView.swift
//  PooPoo Games Watch App
//
//  Created by Admin on 10/18/25.
//

import SwiftUI
import Combine

// Flying Poo
struct WatchFlyingPoo: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat = 20
    var isHit: Bool = false
    var hitAnimationProgress: Double = 0.0
}

// Soap Projectile
struct WatchSoap: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var isFlying: Bool = true
}

// Game State
class WatchSlingPooGameState: ObservableObject {
    enum GamePhase {
        case welcome
        case playing
        case gameOver
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var poos: [WatchFlyingPoo] = []
    @Published var soap: WatchSoap?
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var soapsRemaining: Int = 3
    @Published var slingshotPosition: CGPoint = .zero
    @Published var dragPosition: CGPoint?
    @Published var isAiming: Bool = false
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
    private let gravity: CGFloat = 0.2
    private let maxPullDistance: CGFloat = 50
    
    func startGame() {
        score = 0
        level = 1
        soapsRemaining = 3
        poos = []
        soap = nil
        dragPosition = nil
        isAiming = false
        slingshotPosition = CGPoint(x: screenBounds.width * 0.25, y: screenBounds.height - 40)
        spawnPoos()
        startGameLoop()
        gamePhase = .playing
    }
    
    func spawnPoos() {
        poos = []
        let numPoos = min(3 + level, 8)
        
        for _ in 0..<numPoos {
            let x = CGFloat.random(in: screenBounds.width * 0.5...screenBounds.width - 25)
            let y = CGFloat.random(in: 50...screenBounds.height - 60)
            let vx = CGFloat.random(in: -2...2)
            let vy = CGFloat.random(in: -2...2)
            
            poos.append(WatchFlyingPoo(
                position: CGPoint(x: x, y: y),
                velocity: CGVector(dx: vx, dy: vy)
            ))
        }
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    func updateGame() {
        // Update poos
        for i in 0..<poos.count {
            if poos[i].isHit {
                poos[i].hitAnimationProgress += 0.05
            } else {
                // Move poos
                poos[i].position.x += poos[i].velocity.dx
                poos[i].position.y += poos[i].velocity.dy
                
                // Bounce off walls
                if poos[i].position.x < 15 || poos[i].position.x > screenBounds.width - 15 {
                    poos[i].velocity.dx *= -1
                    poos[i].position.x = max(15, min(screenBounds.width - 15, poos[i].position.x))
                }
                
                if poos[i].position.y < 40 || poos[i].position.y > screenBounds.height - 50 {
                    poos[i].velocity.dy *= -1
                    poos[i].position.y = max(40, min(screenBounds.height - 50, poos[i].position.y))
                }
            }
        }
        
        // Remove fully hit poos
        poos.removeAll { $0.isHit && $0.hitAnimationProgress >= 1.0 }
        
        // Update soap
        if var currentSoap = soap, currentSoap.isFlying {
            // Apply gravity
            currentSoap.velocity.dy += gravity
            
            // Move soap
            currentSoap.position.x += currentSoap.velocity.dx
            currentSoap.position.y += currentSoap.velocity.dy
            
            // Check if soap is off screen
            if currentSoap.position.x < 0 || currentSoap.position.x > screenBounds.width ||
               currentSoap.position.y < 0 || currentSoap.position.y > screenBounds.height {
                soap = nil
                soapsRemaining -= 1
                checkGameOver()
            } else {
                soap = currentSoap
            }
            
            // Check collisions
            checkCollisions()
        }
        
        // Check if level complete
        if poos.isEmpty && soap == nil && gamePhase == .playing {
            levelComplete()
        }
    }
    
    func checkCollisions() {
        guard let currentSoap = soap else { return }
        
        for i in 0..<poos.count {
            if !poos[i].isHit {
                let distance = hypot(currentSoap.position.x - poos[i].position.x,
                                   currentSoap.position.y - poos[i].position.y)
                if distance < 20 {
                    // Hit!
                    poos[i].isHit = true
                    score += 10 * level
                    soap = nil
                }
            }
        }
    }
    
    func startAiming(at position: CGPoint) {
        if soap == nil && soapsRemaining > 0 {
            isAiming = true
            dragPosition = position
        }
    }
    
    func updateAiming(to position: CGPoint) {
        if isAiming {
            dragPosition = position
        }
    }
    
    func releaseSlingshot() {
        guard isAiming, let drag = dragPosition else { return }
        
        // Calculate pull vector
        let pullVector = CGVector(
            dx: slingshotPosition.x - drag.x,
            dy: slingshotPosition.y - drag.y
        )
        
        // Limit pull distance
        let distance = sqrt(pullVector.dx * pullVector.dx + pullVector.dy * pullVector.dy)
        let limitedDistance = min(distance, maxPullDistance)
        let scale = limitedDistance / max(distance, 1)
        
        // Launch soap with velocity based on pull
        let launchVelocity = CGVector(
            dx: pullVector.dx * scale * 0.15,
            dy: pullVector.dy * scale * 0.15
        )
        
        soap = WatchSoap(
            position: slingshotPosition,
            velocity: launchVelocity,
            isFlying: true
        )
        
        isAiming = false
        dragPosition = nil
    }
    
    func levelComplete() {
        level += 1
        soapsRemaining = 3
        spawnPoos()
    }
    
    func checkGameOver() {
        if soapsRemaining <= 0 && soap == nil && !poos.isEmpty {
            gamePhase = .gameOver
            gameTimer?.invalidate()
            gameTimer = nil
        }
    }
}

struct SlingPooView: View {
    @StateObject private var gameState = WatchSlingPooGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if gameState.gamePhase == .welcome {
                    VStack(spacing: 15) {
                        Text("🧼 SLING-POO 💩")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                        
                        Text("Launch soap!")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Button("START") {
                            gameState.startGame()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("HOME") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brown)
                    }
                } else if gameState.gamePhase == .gameOver {
                    VStack(spacing: 10) {
                        Text("GAME OVER")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                        
                        Text("SCORE: \(gameState.score)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Text("LEVEL: \(gameState.level)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Button("AGAIN") {
                            gameState.startGame()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("HOME") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brown)
                    }
                } else {
                    // Playing
                    VStack(spacing: 0) {
                        // Score bar
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(gameState.score)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("L\(gameState.level)")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                ForEach(0..<gameState.soapsRemaining, id: \.self) { _ in
                                    Text("🧼")
                                        .font(.system(size: 10))
                                }
                            }
                        }
                        .padding(5)
                        .background(Color.brown.opacity(0.5))
                        
                        Spacer()
                    }
                    
                    // Flying poos
                    ForEach(gameState.poos) { poo in
                        Text("💩")
                            .font(.system(size: poo.size))
                            .position(poo.position)
                            .opacity(poo.isHit ? 1.0 - poo.hitAnimationProgress : 1.0)
                            .scaleEffect(poo.isHit ? 1.0 + poo.hitAnimationProgress : 1.0)
                    }
                    
                    // Slingshot base
                    ZStack {
                        // Y-shaped slingshot
                        Path { path in
                            path.move(to: CGPoint(x: -8, y: 10))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 8, y: 10))
                        }
                        .stroke(Color.brown, lineWidth: 4)
                        
                        // Base
                        Rectangle()
                            .fill(Color.brown)
                            .frame(width: 20, height: 10)
                            .offset(y: 15)
                        
                        // Elastic bands when aiming
                        if gameState.isAiming, let drag = gameState.dragPosition {
                            Path { path in
                                path.move(to: CGPoint(x: -8, y: 10))
                                path.addLine(to: CGPoint(x: drag.x - gameState.slingshotPosition.x, y: drag.y - gameState.slingshotPosition.y))
                            }
                            .stroke(Color.orange, lineWidth: 2)
                            
                            Path { path in
                                path.move(to: CGPoint(x: 8, y: 10))
                                path.addLine(to: CGPoint(x: drag.x - gameState.slingshotPosition.x, y: drag.y - gameState.slingshotPosition.y))
                            }
                            .stroke(Color.orange, lineWidth: 2)
                            
                            // Soap being pulled
                            Text("🧼")
                                .font(.system(size: 14))
                                .position(drag)
                        } else if gameState.soap == nil && gameState.soapsRemaining > 0 {
                            // Soap ready to launch
                            Text("🧼")
                                .font(.system(size: 14))
                                .offset(y: 5)
                        }
                    }
                    .position(gameState.slingshotPosition)
                    
                    // Flying soap
                    if let soap = gameState.soap {
                        Text("🧼")
                            .font(.system(size: 14))
                            .position(soap.position)
                    }
                }
            }
            .onAppear {
                gameState.screenBounds = geometry.frame(in: .local)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if gameState.gamePhase == .playing {
                            let distance = hypot(
                                value.location.x - gameState.slingshotPosition.x,
                                value.location.y - gameState.slingshotPosition.y
                            )
                            if distance < 70 {
                                if !gameState.isAiming {
                                    gameState.startAiming(at: value.location)
                                } else {
                                    gameState.updateAiming(to: value.location)
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        if gameState.gamePhase == .playing && gameState.isAiming {
                            gameState.releaseSlingshot()
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SlingPooView()
}
