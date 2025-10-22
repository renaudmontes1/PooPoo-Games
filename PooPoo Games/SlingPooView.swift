//
//  SlingPooView.swift
//  PooPoo Games
//
//  Created by Admin on 10/18/25.
//

import SwiftUI
import Combine

// Flying Po`o
struct FlyingPoo: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat = 40
    var isHit: Bool = false
    var hitAnimationProgress: Double = 0.0
}

// Soap Projectile
struct Soap: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var isFlying: Bool = true
}

// Game State
class SlingPooGameState: ObservableObject {
    enum GamePhase {
        case welcome
        case playing
        case gameOver
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var poos: [FlyingPoo] = []
    @Published var soap: Soap?
    @Published var score: Int = 0
    @Published var level: Int = 1
    @Published var soapsRemaining: Int = 3
    @Published var slingshotPosition: CGPoint = .zero
    @Published var dragPosition: CGPoint?
    @Published var isAiming: Bool = false
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
    private let gravity: CGFloat = 0.3
    private let maxPullDistance: CGFloat = 100
    
    func startGame() {
        score = 0
        level = 1
        soapsRemaining = 999  // Unlimited soaps
        poos = []
        soap = nil
        dragPosition = nil
        isAiming = false
        slingshotPosition = CGPoint(x: screenBounds.width * 0.2, y: screenBounds.height - 100)
        spawnPoos()
        startGameLoop()
        gamePhase = .playing
    }
    
    func spawnPoos() {
        poos = []
        let numPoos = min(5 + level, 15)
        
        for _ in 0..<numPoos {
            let x = CGFloat.random(in: screenBounds.width * 0.5...screenBounds.width - 50)
            let y = CGFloat.random(in: 100...screenBounds.height - 150)
            let vx = CGFloat.random(in: -3...3)
            let vy = CGFloat.random(in: -3...3)
            
            poos.append(FlyingPoo(
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
        for i in 0..<poos.count {
            if poos[i].isHit {
                poos[i].hitAnimationProgress += 0.05
            } else {
                poos[i].position.x += poos[i].velocity.dx
                poos[i].position.y += poos[i].velocity.dy
                
                if poos[i].position.x < 30 || poos[i].position.x > screenBounds.width - 30 {
                    poos[i].velocity.dx *= -1
                    poos[i].position.x = max(30, min(screenBounds.width - 30, poos[i].position.x))
                }
                
                if poos[i].position.y < 80 || poos[i].position.y > screenBounds.height - 150 {
                    poos[i].velocity.dy *= -1
                    poos[i].position.y = max(80, min(screenBounds.height - 150, poos[i].position.y))
                }
            }
        }
        
        poos.removeAll { $0.isHit && $0.hitAnimationProgress >= 1.0 }
        
        if var currentSoap = soap, currentSoap.isFlying {
            currentSoap.velocity.dy += gravity
            currentSoap.position.x += currentSoap.velocity.dx
            currentSoap.position.y += currentSoap.velocity.dy
            
            if currentSoap.position.x < 0 || currentSoap.position.x > screenBounds.width ||
               currentSoap.position.y < 0 || currentSoap.position.y > screenBounds.height {
                soap = nil
                soapsRemaining -= 1
                checkGameOver()
            } else {
                soap = currentSoap
            }
            
            checkCollisions()
        }
        
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
                if distance < 30 {
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
        
        let pullVector = CGVector(
            dx: slingshotPosition.x - drag.x,
            dy: slingshotPosition.y - drag.y
        )
        
        let distance = sqrt(pullVector.dx * pullVector.dx + pullVector.dy * pullVector.dy)
        let limitedDistance = min(distance, maxPullDistance)
        let scale = limitedDistance / max(distance, 1)
        
        let launchVelocity = CGVector(
            dx: pullVector.dx * scale * 0.15,
            dy: pullVector.dy * scale * 0.15
        )
        
        soap = Soap(
            position: slingshotPosition,
            velocity: launchVelocity,
            isFlying: true
        )
        
        isAiming = false
        dragPosition = nil
    }
    
    func cancelAiming() {
        isAiming = false
        dragPosition = nil
    }
    
    func levelComplete() {
        level += 1
        soapsRemaining = 999  // Unlimited soaps
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
    @StateObject private var gameState = SlingPooGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if gameState.gamePhase == .welcome {
                    VStack(spacing: 30) {
                        Text("🧼 SLING-POO 💩")
                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                        
                        Text("Launch soap to\nclean the flying poos!")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button("START") {
                            gameState.startGame()
                        }
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 60)
                        .background(Color.green)
                        .cornerRadius(10)
                        
                        Button("HOME") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.brown)
                        .cornerRadius(10)
                    }
                } else if gameState.gamePhase == .gameOver {
                    VStack(spacing: 30) {
                        Text("GAME OVER")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                        
                        Text("FINAL SCORE: \(gameState.score)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Text("LEVEL: \(gameState.level)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.brown)
                        
                        Button("PLAY AGAIN") {
                            gameState.startGame()
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 250, height: 60)
                        .background(Color.green)
                        .cornerRadius(10)
                        
                        Button("HOME") {
                            dismiss()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.brown)
                        .cornerRadius(10)
                    }
                } else {
                    VStack {
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
                            
                            VStack(spacing: 2) {
                                Text("SCORE: \(gameState.score)")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("LEVEL: \(gameState.level)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                            .padding(10)
                            .background(Color.brown.opacity(0.7))
                            .cornerRadius(10)
                            
                            Spacer()
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    ForEach(gameState.poos) { poo in
                        Text("💩")
                            .font(.system(size: poo.size))
                            .position(poo.position)
                            .opacity(poo.isHit ? 1.0 - poo.hitAnimationProgress : 1.0)
                            .scaleEffect(poo.isHit ? 1.0 + poo.hitAnimationProgress : 1.0)
                            .rotationEffect(.degrees(poo.isHit ? poo.hitAnimationProgress * 360 : 0))
                    }
                    
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: -15, y: 20))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 15, y: 20))
                        }
                        .stroke(Color.brown, lineWidth: 8)
                        
                        Rectangle()
                            .fill(Color.brown)
                            .frame(width: 40, height: 20)
                            .offset(y: 30)
                        
                        if gameState.isAiming, let drag = gameState.dragPosition {
                            Path { path in
                                path.move(to: CGPoint(x: -15, y: 20))
                                path.addLine(to: CGPoint(x: drag.x - gameState.slingshotPosition.x, y: drag.y - gameState.slingshotPosition.y))
                            }
                            .stroke(Color.orange, lineWidth: 3)
                            
                            Path { path in
                                path.move(to: CGPoint(x: 15, y: 20))
                                path.addLine(to: CGPoint(x: drag.x - gameState.slingshotPosition.x, y: drag.y - gameState.slingshotPosition.y))
                            }
                            .stroke(Color.orange, lineWidth: 3)
                            
                            Text("🧼")
                                .font(.system(size: 30))
                                .position(drag)
                            
                            let pullVector = CGVector(
                                dx: gameState.slingshotPosition.x - drag.x,
                                dy: gameState.slingshotPosition.y - drag.y
                            )
                            Path { path in
                                path.move(to: gameState.slingshotPosition)
                                for i in 1...8 {
                                    let t = CGFloat(i) * 0.1
                                    let x = gameState.slingshotPosition.x + pullVector.dx * 0.15 * t * 50
                                    let y = gameState.slingshotPosition.y + pullVector.dy * 0.15 * t * 50 + 0.3 * t * t * 250
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            .stroke(Color.black, lineWidth: 4)
                        } else if gameState.soap == nil && gameState.soapsRemaining > 0 {
                            Text("🧼")
                                .font(.system(size: 30))
                                .offset(y: 10)
                        }
                    }
                    .position(gameState.slingshotPosition)
                    
                    if let soap = gameState.soap {
                        Text("🧼")
                            .font(.system(size: 30))
                            .position(soap.position)
                            .rotationEffect(.degrees(Double(soap.velocity.dx) * 10))
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
                            if distance < 150 {
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
