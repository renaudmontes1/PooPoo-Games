//
//  DodgeTheYuckiesView.swift
//  PooPoo Games
//
//  Created by Emilio Montes on 10/18/25.
//

import SwiftUI
import Combine

// MARK: - Models

// Obstacle model
struct Obstacle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let type: ObstacleType
    var isCollected: Bool = false
    
    enum ObstacleType {
        case rottenBanana
        case poo
        case goldenBanana
        
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

// MARK: - Animated Runner Component
struct AnimatedRunner: View {
    let isRunning: Bool
    @State private var animationPhase = 0
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Head with more detail
            // Skin tone head
            context.fill(
                Circle().path(in: CGRect(x: centerX - 12, y: centerY - 35, width: 24, height: 24)),
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65))
            )
            
            // Better hair - more natural looking
            context.fill(
                Path { path in
                    // Left hair tuft
                    path.move(to: CGPoint(x: centerX - 10, y: centerY - 30))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 5, y: centerY - 38),
                        control: CGPoint(x: centerX - 12, y: centerY - 37)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: centerX, y: centerY - 35),
                        control: CGPoint(x: centerX - 3, y: centerY - 39)
                    )
                    
                    // Center/right hair
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 5, y: centerY - 38),
                        control: CGPoint(x: centerX + 3, y: centerY - 39)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + 10, y: centerY - 30),
                        control: CGPoint(x: centerX + 12, y: centerY - 37)
                    )
                    
                    // Connect back around forehead
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - 10, y: centerY - 30),
                        control: CGPoint(x: centerX, y: centerY - 26)
                    )
                },
                with: .color(Color(red: 0.25, green: 0.15, blue: 0.05))
            )
            
            // Eyes
            context.fill(
                Circle().path(in: CGRect(x: centerX - 7, y: centerY - 30, width: 3, height: 3)),
                with: .color(.black)
            )
            context.fill(
                Circle().path(in: CGRect(x: centerX + 4, y: centerY - 30, width: 3, height: 3)),
                with: .color(.black)
            )
            
            // Smile
            context.stroke(
                Path { path in
                    path.addArc(center: CGPoint(x: centerX, y: centerY - 25),
                               radius: 5,
                               startAngle: .degrees(0),
                               endAngle: .degrees(180),
                               clockwise: false)
                },
                with: .color(.black),
                lineWidth: 1
            )
            
            // Neck
            context.fill(
                Rectangle().path(in: CGRect(x: centerX - 4, y: centerY - 11, width: 8, height: 6)),
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65))
            )
            
            // Body - shirt with detail
            context.fill(
                RoundedRectangle(cornerRadius: 8)
                    .path(in: CGRect(x: centerX - 14, y: centerY - 5, width: 28, height: 25)),
                with: .color(Color(red: 0.2, green: 0.5, blue: 0.9))
            )
            
            // Shirt stripe
            context.fill(
                Rectangle().path(in: CGRect(x: centerX - 14, y: centerY + 3, width: 28, height: 3)),
                with: .color(.white.opacity(0.3))
            )
            
            // Arms - animated with realistic RUNNING motion (not panicking!)
            let armSwing = isRunning ? (animationPhase % 2 == 0 ? -12.0 : 12.0) : 0.0
            
            // Left arm - bent at elbow for running
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX - 12, y: centerY - 3))
                    path.addLine(to: CGPoint(x: centerX - 15, y: centerY + 3 + armSwing * 0.5))
                    path.addLine(to: CGPoint(x: centerX - 13, y: centerY + 10 + armSwing))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            
            // Left hand (fist)
            context.fill(
                Capsule().path(in: CGRect(x: centerX - 16, y: centerY + 8 + armSwing, width: 5, height: 4)),
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65))
            )
            
            // Right arm - bent at elbow for running
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX + 12, y: centerY - 3))
                    path.addLine(to: CGPoint(x: centerX + 15, y: centerY + 3 - armSwing * 0.5))
                    path.addLine(to: CGPoint(x: centerX + 13, y: centerY + 10 - armSwing))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            
            // Right hand (fist)
            context.fill(
                Capsule().path(in: CGRect(x: centerX + 11, y: centerY + 8 - armSwing, width: 5, height: 4)),
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65))
            )
            
            // Shorts
            context.fill(
                Rectangle().path(in: CGRect(x: centerX - 12, y: centerY + 20, width: 24, height: 12)),
                with: .color(Color(red: 0.2, green: 0.2, blue: 0.2))
            )
            
            // Legs - animated running motion with realistic skin tone
            let legLift = isRunning ? (animationPhase % 2 == 0 ? -12.0 : 12.0) : 0.0
            
            // Left leg
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX - 6, y: centerY + 32))
                    path.addLine(to: CGPoint(x: centerX - 10, y: centerY + 50 + legLift))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                lineWidth: 7
            )
            
            // Left shoe
            context.fill(
                Ellipse().path(in: CGRect(x: centerX - 16, y: centerY + 48 + legLift, width: 12, height: 6)),
                with: .color(Color(red: 0.9, green: 0.2, blue: 0.2))
            )
            
            // Right leg
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: centerX + 6, y: centerY + 32))
                    path.addLine(to: CGPoint(x: centerX + 10, y: centerY + 50 - legLift))
                },
                with: .color(Color(red: 0.95, green: 0.76, blue: 0.65)),
                lineWidth: 7
            )
            
            // Right shoe
            context.fill(
                Ellipse().path(in: CGRect(x: centerX + 4, y: centerY + 48 - legLift, width: 12, height: 6)),
                with: .color(Color(red: 0.9, green: 0.2, blue: 0.2))
            )
        }
        .frame(width: 60, height: 100)
        .onAppear {
            if isRunning {
                Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                    animationPhase += 1
                }
            }
        }
    }
}

// MARK: - Game State
class DodgeGameState: ObservableObject {
    enum GamePhase {
        case welcome
        case modeSelection
        case playing
        case gameOver
    }
    
    enum Lane {
        case left, center, right
    }
    
    enum ViewMode {
        case twoDimensional
        case threeDimensional
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var viewMode: ViewMode = .twoDimensional
    @Published var score: Int = 0
    @Published var playerLane: Lane = .center
    @Published var isJumping: Bool = false
    @Published var obstacles: [Obstacle] = []
    @Published var gameSpeed: Double = 5.0
    @Published var distance: Double = 0
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
    private var spawnCounter: Int = 0
    private var jumpProgress: Double = 0
    
    func startGame(mode: ViewMode) {
        viewMode = mode
        score = 0
        playerLane = .center
        isJumping = false
        obstacles = []
        gameSpeed = 5.0
        distance = 0
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
        // Update distance
        distance += gameSpeed / 60
        
        // Increase speed gradually
        if Int(distance) % 100 == 0 && distance > 1 {
            gameSpeed = min(gameSpeed + 0.01, 15.0)
        }
        
        // Update jump
        if isJumping {
            jumpProgress += 0.04  // Slower = longer air time (was 0.08)
            if jumpProgress >= 1.0 {
                isJumping = false
                jumpProgress = 0
            }
        }
        
        // Spawn obstacles
        spawnCounter += 1
        if spawnCounter >= Int(60 / gameSpeed * 20) {
            spawnCounter = 0
            spawnObstacle()
        }
        
        // Move obstacles - straight down from top
        for i in 0..<obstacles.count {
            obstacles[i].position.y += gameSpeed
        }
        
        // Check collisions
        checkCollisions()
        
        // Remove off-screen obstacles
        obstacles.removeAll { $0.position.y > screenBounds.height + 50 }
    }
    
    func spawnObstacle() {
        let lanes: [Lane] = [.left, .center, .right]
        let lane = lanes.randomElement() ?? .center
        
        // Random obstacle type
        let random = Double.random(in: 0...1)
        let type: Obstacle.ObstacleType
        if random < 0.15 {
            type = .goldenBanana
        } else if random < 0.6 {
            type = .rottenBanana
        } else {
            type = .poo
        }
        
        let x = laneToX(lane)
        obstacles.append(Obstacle(position: CGPoint(x: x, y: -50), type: type))
    }
    
    func checkCollisions() {
        let playerX = laneToX(playerLane)
        let playerY = screenBounds.height - 150
        
        for i in 0..<obstacles.count {
            if !obstacles[i].isCollected {
                let distance = abs(obstacles[i].position.x - playerX)
                let verticalDistance = abs(obstacles[i].position.y - playerY)
                
                // If jumping, can avoid ground obstacles
                if isJumping && jumpProgress > 0.2 && jumpProgress < 0.8 {
                    continue
                }
                
                if distance < 40 && verticalDistance < 50 {
                    obstacles[i].isCollected = true
                    score += obstacles[i].type.points
                    
                    // Game over if score goes negative
                    if score < 0 {
                        gameOver()
                    }
                }
            }
        }
    }
    
    func moveLeft() {
        switch playerLane {
        case .center:
            playerLane = .left
        case .right:
            playerLane = .center
        case .left:
            break
        }
    }
    
    func moveRight() {
        switch playerLane {
        case .center:
            playerLane = .right
        case .left:
            playerLane = .center
        case .right:
            break
        }
    }
    
    func jump() {
        if !isJumping {
            isJumping = true
            jumpProgress = 0
        }
    }
    
    func laneToX(_ lane: Lane) -> CGFloat {
        switch lane {
        case .left:
            return screenBounds.width * 0.25
        case .center:
            return screenBounds.width * 0.5
        case .right:
            return screenBounds.width * 0.75
        }
    }
    
    func jumpOffset() -> CGFloat {
        if !isJumping { return 0 }
        // Parabolic jump arc - higher and longer
        let progress = jumpProgress
        return -sin(progress * .pi) * 150  // Increased from 100 to 150
    }
    
    func gameOver() {
        gamePhase = .gameOver
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

struct DodgeTheYuckiesView: View {
    @StateObject private var gameState = DodgeGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if gameState.gamePhase == .playing {
                    if gameState.viewMode == .threeDimensional {
                        ThreeDBackground()
                    } else {
                        TwoDBackground()
                    }
                } else {
                    Color.green.opacity(0.3)
                        .ignoresSafeArea()
                }
                
                if gameState.gamePhase == .welcome {
                    WelcomeScreen(gameState: gameState, dismiss: dismiss)
                } else if gameState.gamePhase == .modeSelection {
                    ModeSelectionScreen(gameState: gameState, dismiss: dismiss)
                } else if gameState.gamePhase == .gameOver {
                    GameOverScreen(gameState: gameState, dismiss: dismiss)
                } else {
                    PlayingScreen(gameState: gameState, dismiss: dismiss, geometry: geometry)
                }
            }
            .onAppear {
                gameState.screenBounds = geometry.frame(in: .local)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct WelcomeScreen: View {
    @ObservedObject var gameState: DodgeGameState
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 30) {
            Text("💨 Dodge the Yuckies! 💨")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.brown)
                .multilineTextAlignment(.center)
            
            Text("Dodge poos & rotten bananas!\nCollect golden bananas!")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("START") {
                gameState.gamePhase = .modeSelection
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
    }
}

struct ModeSelectionScreen: View {
    @ObservedObject var gameState: DodgeGameState
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Choose View Mode")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.brown)
            
            Button(action: {
                gameState.startGame(mode: .twoDimensional)
            }) {
                VStack(spacing: 10) {
                    Text("🎮")
                        .font(.system(size: 60))
                    Text("2D View")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Classic Side View")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(width: 250, height: 150)
                .background(Color.blue)
                .cornerRadius(15)
            }
            
            Button(action: {
                gameState.startGame(mode: .threeDimensional)
            }) {
                VStack(spacing: 10) {
                    Text("🎯")
                        .font(.system(size: 60))
                    Text("3D View")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Behind Runner View")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(width: 250, height: 150)
                .background(Color.purple)
                .cornerRadius(15)
            }
            
            Button("BACK") {
                gameState.gamePhase = .welcome
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 200, height: 50)
            .background(Color.brown)
            .cornerRadius(10)
        }
    }
}

struct GameOverScreen: View {
    @ObservedObject var gameState: DodgeGameState
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 30) {
            Text("GAME OVER")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.red)
            
            Text("FINAL SCORE: \(gameState.score)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.brown)
            
            Text("Distance: \(Int(gameState.distance))m")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button("PLAY AGAIN") {
                gameState.gamePhase = .modeSelection
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
    }
}

struct PlayingScreen: View {
    @ObservedObject var gameState: DodgeGameState
    let dismiss: DismissAction
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
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
                
                Text("Score: \(gameState.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
            }
            .padding()
            
            Spacer()
            
            ZStack {
                // Obstacles
                ForEach(gameState.obstacles) { obstacle in
                    if !obstacle.isCollected {
                        Text(obstacle.type.emoji)
                            .font(.system(size: 40))
                            .position(obstacle.position)
                            .scaleEffect(gameState.viewMode == .threeDimensional ? perspectiveScale(y: obstacle.position.y) : 1.0)
                    }
                }
                
                // Player - Animated Runner
                VStack(spacing: 0) {
                    Spacer()
                    
                    AnimatedRunner(isRunning: true)
                        .offset(x: gameState.laneToX(gameState.playerLane) - geometry.size.width / 2)
                        .offset(y: gameState.jumpOffset())
                        .animation(.easeOut(duration: 0.2), value: gameState.playerLane)
                        .padding(.bottom, 100)
                }
            }
            
            // Controls
            HStack(spacing: 50) {
                Button(action: { gameState.moveLeft() }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                Button(action: { gameState.jump() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                Button(action: { gameState.moveRight() }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    func perspectiveScale(y: CGFloat) -> CGFloat {
        let maxY = geometry.size.height
        let scale = 0.3 + (y / maxY) * 0.7
        return max(0.3, min(1.0, scale))
    }
}

// MARK: - Backgrounds

struct TwoDBackground: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Beautiful sky gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.53, green: 0.81, blue: 0.92),
                    Color(red: 0.68, green: 0.85, blue: 0.90)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Sun
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange.opacity(0.7)]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .offset(x: -120, y: -250)
            
            // Fluffy clouds
            GeometryReader { geometry in
                ForEach(0..<4) { i in
                    CloudShape()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 120, height: 40)
                        .offset(x: CGFloat(i) * 140 + scrollOffset * 0.3, y: 60 + CGFloat(i) * 40)
                }
            }
            
            // Distant mountains
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.35))
                    path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.45))
                    path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.3))
                    path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.4))
                    path.addLine(to: CGPoint(x: width, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.5, blue: 0.6),
                            Color(red: 0.5, green: 0.6, blue: 0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Green rolling hills
            VStack(spacing: 0) {
                Spacer()
                
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height: CGFloat = 150
                        
                        path.move(to: CGPoint(x: 0, y: height * 0.5))
                        
                        for i in stride(from: 0, through: width, by: 50) {
                            let y = height * 0.5 + sin((i + scrollOffset) / 30) * 20
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
                                Color(red: 0.2, green: 0.6, blue: 0.2)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                
                // Path/road
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.7, green: 0.6, blue: 0.5),
                                Color(red: 0.6, green: 0.5, blue: 0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 80)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                scrollOffset -= 2
                if scrollOffset < -400 {
                    scrollOffset = 0
                }
            }
        }
    }
}

// Cloud shape helper
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Main cloud body with multiple circles
        path.addEllipse(in: CGRect(x: rect.minX + 20, y: rect.minY + 10, width: 40, height: 25))
        path.addEllipse(in: CGRect(x: rect.minX + 40, y: rect.minY + 5, width: 45, height: 30))
        path.addEllipse(in: CGRect(x: rect.minX + 60, y: rect.minY + 10, width: 40, height: 25))
        
        return path
    }
}

// Tree view helper - Much better looking!
struct TreeView: View {
    var body: some View {
        ZStack {
            // Trunk with texture
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.25, blue: 0.15),
                            Color(red: 0.5, green: 0.35, blue: 0.2),
                            Color(red: 0.35, green: 0.2, blue: 0.1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 18, height: 45)
                .offset(y: 20)
            
            // Layered foliage - looks way more natural
            // Bottom layer
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.25, green: 0.65, blue: 0.25),
                            Color(red: 0.15, green: 0.5, blue: 0.15)
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 50)
                .offset(y: 10)
            
            // Middle layer
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.7, blue: 0.3),
                            Color(red: 0.2, green: 0.6, blue: 0.2)
                        ]),
                        center: .top,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 45)
                .offset(y: -5)
            
            // Top layer
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.35),
                            Color(red: 0.25, green: 0.65, blue: 0.25)
                        ]),
                        center: .top,
                        startRadius: 3,
                        endRadius: 22
                    )
                )
                .frame(width: 45, height: 35)
                .offset(y: -18)
        }
        .frame(width: 70, height: 80)
    }
}

struct ThreeDBackground: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful sky with gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.6, blue: 0.95),
                        Color(red: 0.6, green: 0.75, blue: 0.95),
                        Color(red: 0.75, green: 0.85, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                // Sun in the distance
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.5), Color.clear]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .offset(x: 80, y: -geometry.size.height * 0.3)
                
                // Distant mountains with depth
                Path { path in
                    let width = geometry.size.width
                    let horizonY = geometry.size.height * 0.3
                    
                    path.move(to: CGPoint(x: 0, y: horizonY + 50))
                    path.addLine(to: CGPoint(x: width * 0.15, y: horizonY - 20))
                    path.addLine(to: CGPoint(x: width * 0.35, y: horizonY + 30))
                    path.addLine(to: CGPoint(x: width * 0.55, y: horizonY - 40))
                    path.addLine(to: CGPoint(x: width * 0.75, y: horizonY + 20))
                    path.addLine(to: CGPoint(x: width, y: horizonY + 10))
                    path.addLine(to: CGPoint(x: width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.6),
                            Color(red: 0.4, green: 0.6, blue: 0.5).opacity(0.7)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Grass field with perspective
                Path { path in
                    let horizonY = geometry.size.height * 0.45
                    
                    path.move(to: CGPoint(x: 0, y: horizonY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: horizonY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.4, green: 0.7, blue: 0.3),
                            Color(red: 0.3, green: 0.55, blue: 0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // 3D Road with natural perspective
                Canvas { context, size in
                    let horizonY = size.height * 0.45
                    let bottomY = size.height
                    
                    // Road gets narrower toward horizon
                    let roadPath = Path { path in
                        path.move(to: CGPoint(x: size.width * 0.25, y: bottomY))
                        path.addLine(to: CGPoint(x: size.width * 0.44, y: horizonY))
                        path.addLine(to: CGPoint(x: size.width * 0.56, y: horizonY))
                        path.addLine(to: CGPoint(x: size.width * 0.75, y: bottomY))
                        path.closeSubpath()
                    }
                    
                    // Asphalt road with gradient
                    context.fill(
                        roadPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.3, green: 0.3, blue: 0.3),
                                Color(red: 0.25, green: 0.25, blue: 0.25)
                            ]),
                            startPoint: CGPoint(x: size.width * 0.5, y: horizonY),
                            endPoint: CGPoint(x: size.width * 0.5, y: bottomY)
                        )
                    )
                    
                    // Road center line dashes - properly spaced
                    for i in 0..<10 {
                        let progress = CGFloat(i) / 10.0
                        let baseY = bottomY - (bottomY - horizonY) * progress
                        let animatedOffset = CGFloat(Int(scrollOffset * 0.8) % 100)
                        let y = baseY + animatedOffset
                        
                        // Only draw if on the road
                        if y > horizonY && y < bottomY {
                            let width = 4 + (1 - progress) * 10
                            let height = 12 * (1 - progress * 0.5)
                            
                            let dash = RoundedRectangle(cornerRadius: 2)
                                .path(in: CGRect(
                                    x: size.width * 0.5 - width/2,
                                    y: y,
                                    width: width,
                                    height: height
                                ))
                            
                            context.fill(dash, with: .color(.yellow.opacity(0.9)))
                        }
                    }
                    
                    // Lane dividers - subtle white lines
                    let leftLanePath = Path { p in
                        p.move(to: CGPoint(x: size.width * 0.35, y: bottomY))
                        p.addLine(to: CGPoint(x: size.width * 0.47, y: horizonY))
                    }
                    
                    let rightLanePath = Path { p in
                        p.move(to: CGPoint(x: size.width * 0.65, y: bottomY))
                        p.addLine(to: CGPoint(x: size.width * 0.53, y: horizonY))
                    }
                    
                    context.stroke(leftLanePath, with: .color(.white.opacity(0.3)), lineWidth: 2)
                    context.stroke(rightLanePath, with: .color(.white.opacity(0.3)), lineWidth: 2)
                }
                
                // Grass on sides
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.2),
                                Color(red: 0.15, green: 0.5, blue: 0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.25)
                    .offset(x: -geometry.size.width * 0.375)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.2),
                                Color(red: 0.15, green: 0.5, blue: 0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 0.25)
                    .offset(x: geometry.size.width * 0.375)
                
                // Trees along the road
                ForEach(0..<8) { i in
                    let progress = CGFloat(i) / 8.0
                    let y = geometry.size.height * 0.45 + (geometry.size.height * 0.55 - geometry.size.height * 0.45) * progress + scrollOffset * 0.6
                    let scale = 0.3 + progress * 0.7
                    
                    TreeView()
                        .scaleEffect(scale)
                        .offset(
                            x: (i % 2 == 0 ? -1 : 1) * (geometry.size.width * 0.35 - (1 - progress) * 50),
                            y: y
                        )
                        .opacity(0.7 + progress * 0.3)
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                    scrollOffset -= 3
                    if scrollOffset < -300 {
                        scrollOffset = 0
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DodgeTheYuckiesView()
}
