//
//  DodgeTheYuckiesView.swift
//  PooPoo Games Watch App
//
//  Created by Renaud Montes on 10/18/25.
//

import SwiftUI
import Combine

// MARK: - Animated Runner for Watch
struct WatchAnimatedRunner: View {
    let isRunning: Bool
    @State private var animationPhase = 0
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Head
            context.fill(
                Circle().path(in: CGRect(x: centerX - 6, y: centerY - 17, width: 12, height: 12)),
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65))
            )
            
            // Better hair - more natural
            context.fill(
                Path { path in
                    path.move(to: CGPoint(x: centerX - 5, y: centerY - 14))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 2, y: centerY - 19),
                        control: CGPoint(x: centerX - 6, y: centerY - 18)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 2, y: centerY - 19),
                        control: CGPoint(x: centerX, y: centerY - 20)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 5, y: centerY - 14),
                        control: CGPoint(x: centerX + 6, y: centerY - 18)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 5, y: centerY - 14),
                        control: CGPoint(x: centerX, y: centerY - 12)
                    )
                },
                with: .color(Color(red: 0.25, green: 0.15, blue: 0.05))
            )
            
            // Eyes
            context.fill(
                Circle().path(in: CGRect(x: centerX - 4, y: centerY - 15, width: 1.5, height: 1.5)),
                with: .color(.black)
            )
            context.fill(
                Circle().path(in: CGRect(x: centerX + 2.5, y: centerY - 15, width: 1.5, height: 1.5)),
                with: .color(.black)
            )
            
            // Body - shirt
            context.fill(
                RoundedRectangle(cornerRadius: 4)
                    .path(in: CGRect(x: centerX - 7, y: centerY - 5, width: 14, height: 12)),
                with: .color(Color(red: 0.2, green: 0.5, blue: 0.9))
            )
            
            // Arms - proper running motion (not panic waving!)
            let armSwing = isRunning ? (animationPhase % 2 == 0 ? -8.0 : 8.0) : 0.0
            
            // Left arm - bent for running
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX - 6, y: centerY - 2))
                    path.addLine(to: CGPoint(x: centerX - 8, y: centerY + 2 + armSwing * 0.5))
                    path.addLine(to: CGPoint(x: centerX - 7, y: centerY + 6 + armSwing))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            
            // Right arm - bent for running
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX + 6, y: centerY - 2))
                    path.addLine(to: CGPoint(x: centerX + 8, y: centerY + 2 - armSwing * 0.5))
                    path.addLine(to: CGPoint(x: centerX + 7, y: centerY + 6 - armSwing))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            
            // Shorts
            context.fill(
                Rectangle().path(in: CGRect(x: centerX - 6, y: centerY + 7, width: 12, height: 6)),
                with: .color(Color(red: 0.2, green: 0.2, blue: 0.2))
            )
            
            // Legs - animated
            let legLift = isRunning ? (animationPhase % 2 == 0 ? -6.0 : 6.0) : 0.0
            
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX - 3, y: centerY + 13))
                    path.addLine(to: CGPoint(x: centerX - 5, y: centerY + 24 + legLift))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                lineWidth: 3.5
            )
            
            // Shoes
            context.fill(
                Ellipse().path(in: CGRect(x: centerX - 8, y: centerY + 22 + legLift, width: 6, height: 3)),
                with: .color(Color(red: 0.9, green: 0.2, blue: 0.2))
            )
            
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX + 3, y: centerY + 13))
                    path.addLine(to: CGPoint(x: centerX + 5, y: centerY + 24 - legLift))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                lineWidth: 3.5
            )
            
            context.fill(
                Ellipse().path(in: CGRect(x: centerX + 2, y: centerY + 22 - legLift, width: 6, height: 3)),
                with: .color(Color(red: 0.9, green: 0.2, blue: 0.2))
            )
        }
        .frame(width: 30, height: 50)
        .onAppear {
            if isRunning {
                Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                    animationPhase += 1
                }
            }
        }
    }
}

// Use same Obstacle model as iOS
struct WatchObstacle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let type: ObstacleType
    var isCollected: Bool = false
    
    enum ObstacleType {
        case rottenBanana, poo, goldenBanana
        
        var emoji: String {
            switch self {
            case .rottenBanana: return "🍌"
            case .poo: return "💩"
            case .goldenBanana: return "✨🍌"
            }
        }
        
        var points: Int {
            switch self {
            case .rottenBanana, .poo: return -10
            case .goldenBanana: return 10
            }
        }
    }
}

class WatchDodgeGameState: ObservableObject {
    enum GamePhase {
        case welcome, playing, gameOver
    }
    
    enum Lane {
        case left, right
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var score: Int = 0
    @Published var playerLane: Lane = .left
    @Published var isJumping: Bool = false
    @Published var obstacles: [WatchObstacle] = []
    @Published var gameSpeed: Double = 3.0
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
    private var spawnCounter: Int = 0
    private var jumpProgress: Double = 0
    
    func startGame() {
        score = 0
        playerLane = .left
        isJumping = false
        obstacles = []
        gameSpeed = 3.0
        spawnCounter = 0
        jumpProgress = 0
        gamePhase = .playing
        startGameLoop()
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    func updateGame() {
        gameSpeed = min(gameSpeed + 0.001, 8.0)
        
        if isJumping {
            jumpProgress += 0.04  // Slower = longer air time (was 0.08)
            if jumpProgress >= 1.0 {
                isJumping = false
                jumpProgress = 0
            }
        }
        
        spawnCounter += 1
        if spawnCounter >= Int(60 / gameSpeed * 25) {
            spawnCounter = 0
            spawnObstacle()
        }
        
        // Move obstacles straight down
        for i in 0..<obstacles.count {
            obstacles[i].position.y += gameSpeed
        }
        
        checkCollisions()
        obstacles.removeAll { $0.position.y > screenBounds.height + 30 }
    }
    
    func spawnObstacle() {
        let lane: Lane = Bool.random() ? .left : .right
        let random = Double.random(in: 0...1)
        let type: WatchObstacle.ObstacleType = random < 0.2 ? .goldenBanana : (random < 0.6 ? .rottenBanana : .poo)
        
        let x = laneToX(lane)
        obstacles.append(WatchObstacle(position: CGPoint(x: x, y: -30), type: type))
    }
    
    func checkCollisions() {
        let playerX = laneToX(playerLane)
        let playerY = screenBounds.height - 60
        
        for i in 0..<obstacles.count {
            if !obstacles[i].isCollected {
                let distance = abs(obstacles[i].position.x - playerX)
                let verticalDistance = abs(obstacles[i].position.y - playerY)
                
                if isJumping && jumpProgress > 0.2 && jumpProgress < 0.8 {
                    continue
                }
                
                if distance < 20 && verticalDistance < 30 {
                    obstacles[i].isCollected = true
                    score += obstacles[i].type.points
                    
                    if score < 0 {
                        gameOver()
                    }
                }
            }
        }
    }
    
    func toggleLane() {
        playerLane = playerLane == .left ? .right : .left
    }
    
    func jump() {
        if !isJumping {
            isJumping = true
            jumpProgress = 0
        }
    }
    
    func laneToX(_ lane: Lane) -> CGFloat {
        lane == .left ? screenBounds.width * 0.35 : screenBounds.width * 0.65
    }
    
    func jumpOffset() -> CGFloat {
        isJumping ? -sin(jumpProgress * .pi) * 60 : 0  // Increased from 40 to 60
    }
    
    func gameOver() {
        gamePhase = .gameOver
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

struct DodgeTheYuckiesView: View {
    @StateObject private var gameState = WatchDodgeGameState()
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if gameState.gamePhase == .playing {
                    // Natural animated background
                    ZStack {
                        // Sky gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.75, blue: 0.95),
                                Color(red: 0.65, green: 0.82, blue: 0.95)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        // Sun
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.clear]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 30, height: 30)
                            .offset(x: -50, y: -60)
                        
                        // Rolling hills
                        VStack {
                            Spacer()
                            GeometryReader { geo in
                                Path { path in
                                    let width = geo.size.width
                                    let height: CGFloat = 40
                                    
                                    path.move(to: CGPoint(x: 0, y: height * 0.5))
                                    
                                    for i in stride(from: 0, through: width, by: 20) {
                                        let y = height * 0.5 + sin((i + scrollOffset) / 15) * 8
                                        path.addLine(to: CGPoint(x: i, y: y))
                                    }
                                    
                                    path.addLine(to: CGPoint(x: width, y: height))
                                    path.addLine(to: CGPoint(x: 0, y: height))
                                    path.closeSubpath()
                                }
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.3, green: 0.7, blue: 0.3),
                                            Color(red: 0.25, green: 0.6, blue: 0.25)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .frame(height: 40)
                            
                            // Path
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.65, green: 0.55, blue: 0.45),
                                            Color(red: 0.55, green: 0.45, blue: 0.35)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 30)
                        }
                        .ignoresSafeArea(edges: .bottom)
                    }
                    .onAppear {
                        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                            if gameState.gamePhase == .playing {
                                scrollOffset -= 2
                                if scrollOffset < -200 {
                                    scrollOffset = 0
                                }
                            }
                        }
                    }
                } else {
                    Color.green.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                if gameState.gamePhase == .welcome {
                    VStack(spacing: 10) {
                        Text("💨 Dodge! 💨")
                            .font(.headline)
                            .foregroundColor(.brown)
                        
                        Text("Dodge yuckies!\nGet gold bananas!")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
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
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text("Score: \(gameState.score)")
                            .font(.caption)
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
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 12))
                            }
                            
                            Spacer()
                            
                            Text("\(gameState.score)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(5)
                        
                        Spacer()
                        
                        ZStack {
                            ForEach(gameState.obstacles) { obstacle in
                                if !obstacle.isCollected {
                                    Text(obstacle.type.emoji)
                                        .font(.system(size: 20))
                                        .position(obstacle.position)
                                }
                            }
                            
                            VStack {
                                Spacer()
                                
                                WatchAnimatedRunner(isRunning: true)
                                    .offset(x: gameState.laneToX(gameState.playerLane) - geometry.size.width / 2)
                                    .offset(y: gameState.jumpOffset())
                                    .animation(.easeOut(duration: 0.15), value: gameState.playerLane)
                                    .padding(.bottom, 50)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            Button(action: { gameState.toggleLane() }) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: { gameState.jump() }) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .onAppear {
                gameState.screenBounds = geometry.frame(in: .local)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    DodgeTheYuckiesView()
}
