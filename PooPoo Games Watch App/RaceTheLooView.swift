//
//  RaceTheLooView.swift
//  PooPoo Games Watch App
//
//  Created by Emilio Montes on 10/18/25.
//

import SwiftUI
import Combine

// MARK: - Models

enum Difficulty {
    case easy, medium, hard
    
    var aiAccelerationChance: Double {
        switch self {
        case .easy: return 0.40
        case .medium: return 0.20
        case .hard: return 0.10
        }
    }
    
    var aiAcceleration: CGFloat {
        switch self {
        case .easy: return 0.035
        case .medium: return 0.055
        case .hard: return 0.075
        }
    }
    
    var aiMaxSpeed: CGFloat {
        switch self {
        case .easy: return 0.9
        case .medium: return 1.2
        case .hard: return 1.6
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

enum TrackType {
    case straightaway, sCurve, hairpin, chicane
    
    var displayName: String {
        switch self {
        case .straightaway: return "Straightaway"
        case .sCurve: return "S-Curve"
        case .hairpin: return "Hairpin"
        case .chicane: return "Chicane"
        }
    }
}

struct WatchRacer {
    var position: CGFloat = 0  // 0 to 500
    var lanePosition: CGFloat = 0.5  // 0.3 = left, 0.7 = right
    var speed: CGFloat = 0
    var realSpeed: CGFloat = 0  // MPH for display
}

// MARK: - Game State

class WatchRaceGameState: ObservableObject {
    enum GamePhase {
        case welcome, selectDifficulty, selectTrack, racing, finished
    }
    
    enum CrashType {
        case wall, collision
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var playerRacer = WatchRacer()
    @Published var pooRacer = WatchRacer()
    @Published var winner: String = ""
    @Published var crownValue: Double = 0
    @Published var selectedDifficulty: Difficulty = .medium
    @Published var selectedTrack: TrackType = .straightaway
    @Published var crashType: CrashType?
    
    private var gameTimer: Timer?
    private var aiTimer: Timer?
    
    func startRace() {
        playerRacer = WatchRacer()
        pooRacer = WatchRacer()
        winner = ""
        crownValue = 0
        crashType = nil
        gamePhase = .racing
        
        startGameLoop()
        startAI()
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.updateRace()
        }
    }
    
    func startAI() {
        aiTimer?.invalidate()
        aiTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAI()
        }
    }
    
    func updateRace() {
        // Update positions
        playerRacer.position += playerRacer.speed
        pooRacer.position += pooRacer.speed
        
        // Calculate real MPH
        playerRacer.realSpeed = playerRacer.speed * 60
        pooRacer.realSpeed = pooRacer.speed * 60
        
        // Decay speed
        playerRacer.speed *= 0.98
        pooRacer.speed *= 0.98
        
        // Clamp positions
        playerRacer.position = max(0, min(500, playerRacer.position))
        pooRacer.position = max(0, min(500, pooRacer.position))
        
        // Check for wall collisions
        if checkWallCollision(racer: playerRacer) {
            winner = "Poo"
            crashType = .wall
            finishRace()
            return
        }
        
        if checkWallCollision(racer: pooRacer) {
            winner = "You"
            crashType = .wall
            finishRace()
            return
        }
        
        // Check for collision between racers
        if checkRacerCollision() {
            if playerRacer.position > pooRacer.position {
                winner = "You"
            } else {
                winner = "Poo"
            }
            crashType = .collision
            finishRace()
            return
        }
        
        // Check for winner
        if playerRacer.position >= 500 {
            winner = "You"
            finishRace()
        } else if pooRacer.position >= 500 {
            winner = "Poo"
            finishRace()
        }
    }
    
    func checkWallCollision(racer: WatchRacer) -> Bool {
        if racer.position < 10 {
            return false
        }
        let turnAmount = getTurnAmountForPosition(progress: racer.position, trackType: selectedTrack)
        let roadLeftBoundary = 0.25 + turnAmount * 0.35
        let roadRightBoundary = 0.75 + turnAmount * 0.35
        let racerLeft = racer.lanePosition - 0.15
        let racerRight = racer.lanePosition + 0.15
        let safeLeftBoundary = roadLeftBoundary - 0.05
        let safeRightBoundary = roadRightBoundary + 0.05
        return racerLeft < safeLeftBoundary || racerRight > safeRightBoundary
    }
    
    func checkRacerCollision() -> Bool {
        if playerRacer.position < 20 && pooRacer.position < 20 {
            return false
        }
        let positionDiff = abs(playerRacer.position - pooRacer.position)
        let laneDiff = abs(playerRacer.lanePosition - pooRacer.lanePosition)
        return positionDiff < 5 && laneDiff < 0.15
    }
    
    func getTurnAmountForPosition(progress: CGFloat, trackType: TrackType) -> CGFloat {
        switch trackType {
        case .straightaway:
            if progress < 200 { return 0 }
            else if progress < 275 { return (progress - 200) / 75.0 }
            else if progress < 350 { return 1.0 - (progress - 275) / 75.0 }
            else { return 0 }
        case .sCurve:
            if progress < 100 { return 0 }
            else if progress < 150 { return (progress - 100) / 50.0 }
            else if progress < 200 { return 1.0 - (progress - 150) / 50.0 }
            else if progress < 250 { return -((progress - 200) / 50.0) }
            else if progress < 300 { return -(1.0 - (progress - 250) / 50.0) }
            else if progress < 350 { return (progress - 300) / 50.0 }
            else if progress < 400 { return 1.0 - (progress - 350) / 50.0 }
            else { return 0 }
        case .hairpin:
            if progress < 150 { return 0 }
            else if progress < 220 { return ((progress - 150) / 70.0) * 1.5 }
            else if progress < 280 { return 1.5 }
            else if progress < 350 { return 1.5 - ((progress - 280) / 70.0) * 1.5 }
            else { return 0 }
        case .chicane:
            if progress < 120 { return 0 }
            else if progress < 160 { return -((progress - 120) / 40.0) * 0.8 }
            else if progress < 200 { return -0.8 + ((progress - 160) / 40.0) * 1.6 }
            else if progress < 240 { return 0.8 - ((progress - 200) / 40.0) * 1.6 }
            else if progress < 280 { return -0.8 + ((progress - 240) / 40.0) * 0.8 }
            else if progress < 340 { return -((progress - 280) / 30.0) * 0.6 }
            else if progress < 380 { return -0.6 + ((progress - 340) / 40.0) * 1.2 }
            else if progress < 420 { return 0.6 - ((progress - 380) / 40.0) * 0.6 }
            else { return 0 }
        }
    }
    
    func updateAI() {
        if Double.random(in: 0...1) < (1.0 - selectedDifficulty.aiAccelerationChance) {
            pooRacer.speed = min(pooRacer.speed + selectedDifficulty.aiAcceleration, selectedDifficulty.aiMaxSpeed)
        }
        
        // Smart lane selection based on track curves and player position
        let currentTurn = getTurnAmountForPosition(progress: pooRacer.position, trackType: selectedTrack)
        let positionDiff = abs(playerRacer.position - pooRacer.position)
        let isPlayerClose = positionDiff < 15
        
        // First priority: Avoid walls by staying in safe lanes during turns
        // More aggressive wall avoidance with lower threshold
        if abs(currentTurn) > 0.2 {  // Lower threshold for earlier detection
            // In a turn - always choose the safest lane
            if currentTurn > 0 {
                // Right turn - ALWAYS use left lane (0.3)
                pooRacer.lanePosition = 0.3
            } else if currentTurn < 0 {
                // Left turn - ALWAYS use right lane (0.7)
                pooRacer.lanePosition = 0.7
            }
        }
        // Second priority: Avoid player collision
        else if isPlayerClose && abs(playerRacer.lanePosition - pooRacer.lanePosition) < 0.2 {
            // Move to different lane to avoid collision
            pooRacer.lanePosition = pooRacer.lanePosition == 0.3 ? 0.7 : 0.3
        }
        // Third priority: Stay centered on straights
        else if abs(currentTurn) < 0.1 {
            // On straight sections, stay in safe default lane
            pooRacer.lanePosition = 0.5
        }
    }
    
    func onCrownRotate(delta: Double) {
        // Digital Crown accelerates
        crownValue += delta
        if delta > 0 {
            playerRacer.speed = min(playerRacer.speed + CGFloat(delta) * 0.3, 1.5)
        }
    }
    
    func tapLeft() {
        playerRacer.lanePosition = 0.3
    }
    
    func tapRight() {
        playerRacer.lanePosition = 0.7
    }
    
    func brake() {
        playerRacer.speed = max(playerRacer.speed - 0.15, 0)
    }
    
    func finishRace() {
        gamePhase = .finished
        gameTimer?.invalidate()
        aiTimer?.invalidate()
    }
}

// MARK: - Main View

struct RaceTheLooView: View {
    @StateObject private var gameState = WatchRaceGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            if gameState.gamePhase == .racing {
                WatchRacingView(gameState: gameState)
            } else if gameState.gamePhase == .finished {
                WatchFinishView(gameState: gameState, dismiss: dismiss)
            } else if gameState.gamePhase == .selectDifficulty {
                WatchDifficultyView(gameState: gameState)
            } else if gameState.gamePhase == .selectTrack {
                WatchTrackView(gameState: gameState)
            } else {
                WatchWelcomeView(gameState: gameState, dismiss: dismiss)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Welcome Screen

struct WatchWelcomeView: View {
    @ObservedObject var gameState: WatchRaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 10) {
            Text("🏁 Race! 🚽")
                .font(.headline)
                .foregroundColor(.brown)
            
            Text("🏎️ vs 💩")
                .font(.title)
            
            Text("Beat poo to the toilet!")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("START") {
                gameState.gamePhase = .selectDifficulty
            }
            .buttonStyle(.bordered)
            
            Text("Turn Crown to GO!")
                .font(.caption2)
                .foregroundColor(.green)
            
            Text("Tap brake to slow!")
                .font(.caption2)
                .foregroundColor(.red)
            
            Button("HOME") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
    }
}

// MARK: - Difficulty Selection

struct WatchDifficultyView: View {
    @ObservedObject var gameState: WatchRaceGameState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Difficulty")
                    .font(.headline)
                    .foregroundColor(.brown)
                
                Button(action: {
                    gameState.selectedDifficulty = .easy
                    gameState.gamePhase = .selectTrack
                }) {
                    VStack {
                        Text("😊 Easy")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Button(action: {
                    gameState.selectedDifficulty = .medium
                    gameState.gamePhase = .selectTrack
                }) {
                    VStack {
                        Text("😐 Medium")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: {
                    gameState.selectedDifficulty = .hard
                    gameState.gamePhase = .selectTrack
                }) {
                    VStack {
                        Text("😰 Hard")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button("BACK") {
                    gameState.gamePhase = .welcome
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
                .font(.caption2)
            }
        }
    }
}

// MARK: - Track Selection

struct WatchTrackView: View {
    @ObservedObject var gameState: WatchRaceGameState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Track")
                    .font(.headline)
                    .foregroundColor(.brown)
                
                Text(gameState.selectedDifficulty.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    gameState.selectedTrack = .straightaway
                    gameState.startRace()
                }) {
                    Text("→ Straight")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    gameState.selectedTrack = .sCurve
                    gameState.startRace()
                }) {
                    Text("〰️ S-Curve")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    gameState.selectedTrack = .hairpin
                    gameState.startRace()
                }) {
                    Text("↪️ Hairpin")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    gameState.selectedTrack = .chicane
                    gameState.startRace()
                }) {
                    Text("⚡️ Chicane")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button("BACK") {
                    gameState.gamePhase = .selectDifficulty
                }
                .buttonStyle(.borderedProminent)
                .tint(.brown)
                .font(.caption2)
            }
        }
    }
}

// MARK: - Racing View

struct WatchRacingView: View {
    @ObservedObject var gameState: WatchRaceGameState
    @State private var scrollAmount = 0.0
    @State private var previousScrollAmount = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let turnAmount = getTurnAmount(progress: gameState.playerRacer.position)
            
            ZStack {
                // Grass background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 0.2),
                        Color(red: 0.3, green: 0.7, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Road with perspective and turn
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let roadWidth: CGFloat = 0.5
                    
                    let leftEdge = 0.5 - roadWidth/2 + turnAmount * 0.1
                    let rightEdge = 0.5 + roadWidth/2 + turnAmount * 0.1
                    
                    path.move(to: CGPoint(x: width * leftEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.4 + turnAmount * 0.05), y: 0))
                    path.addLine(to: CGPoint(x: width * (0.6 + turnAmount * 0.05), y: 0))
                    path.addLine(to: CGPoint(x: width * rightEdge, y: height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                
                // Road edge lines (white)
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let roadWidth: CGFloat = 0.5
                    
                    let leftEdge = 0.5 - roadWidth/2 + turnAmount * 0.1
                    let rightEdge = 0.5 + roadWidth/2 + turnAmount * 0.1
                    
                    // Left edge
                    path.move(to: CGPoint(x: width * leftEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.4 + turnAmount * 0.05), y: 0))
                    
                    // Right edge
                    path.move(to: CGPoint(x: width * rightEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.6 + turnAmount * 0.05), y: 0))
                }
                .stroke(Color.white, lineWidth: 2)
                
                // Red/white curbing
                Canvas { context, size in
                    for i in 0..<12 {
                        let progress = CGFloat(i) / 12.0
                        let y = size.height * (1 - progress)
                        let color: Color = (i + Int(gameState.playerRacer.position / 10)) % 2 == 0 ? .red : .white
                        
                        let leftEdge = 0.5 - 0.25 + turnAmount * 0.1
                        let rightEdge = 0.5 + 0.25 + turnAmount * 0.1
                        
                        let leftX = size.width * (leftEdge + (0.4 + turnAmount * 0.05 - leftEdge) * progress)
                        let rightX = size.width * (rightEdge + (0.6 + turnAmount * 0.05 - rightEdge) * progress)
                        
                        // Left curb
                        let leftRect = Rectangle()
                            .path(in: CGRect(x: leftX - 4, y: y, width: 4, height: size.height / 12))
                        context.fill(leftRect, with: .color(color))
                        
                        // Right curb
                        let rightRect = Rectangle()
                            .path(in: CGRect(x: rightX, y: y, width: 4, height: size.height / 12))
                        context.fill(rightRect, with: .color(color))
                    }
                }
                
                // Center yellow dashed lines
                Canvas { context, size in
                    for i in 0..<10 {
                        let progress = CGFloat(i) / 10.0
                        let y = size.height * progress + CGFloat(Int(scrollAmount) % 30)
                        let lineWidth = 2 + (1 - progress) * 3
                        let centerX = 0.5 + turnAmount * 0.05 * progress
                        
                        let rect = Rectangle()
                            .path(in: CGRect(
                                x: size.width * centerX - lineWidth / 2,
                                y: y,
                                width: lineWidth,
                                height: 12 * (1 - progress * 0.5)
                            ))
                        
                        context.fill(rect, with: .color(.yellow))
                    }
                }
                
                // Start/Finish line checkered pattern
                if gameState.playerRacer.position > 480 {
                    Canvas { context, size in
                        for x in 0..<10 {
                            for y in 0..<2 {
                                let isBlack = (x + y) % 2 == 0
                                let rect = Rectangle()
                                    .path(in: CGRect(
                                        x: size.width * 0.25 + CGFloat(x) * size.width * 0.05,
                                        y: size.height * 0.3 + CGFloat(y) * 5,
                                        width: size.width * 0.05,
                                        height: 5
                                    ))
                                context.fill(rect, with: .color(isBlack ? .black : .white))
                            }
                        }
                    }
                }
                
                // Racers
                VStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        if gameState.playerRacer.lanePosition < 0.5 {
                            WatchGoKart(isPlayer: true, speed: gameState.playerRacer.speed)
                            Spacer()
                        } else {
                            Spacer()
                            WatchGoKart(isPlayer: true, speed: gameState.playerRacer.speed)
                        }
                    }
                    .frame(width: geometry.size.width * 0.6)
                    .padding(.bottom, 40)
                }
                
                // Poo racer (relative position)
                let pooOffset = (gameState.pooRacer.position - gameState.playerRacer.position) * -3
                if abs(pooOffset) < geometry.size.height * 0.5 {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            if gameState.pooRacer.lanePosition < 0.5 {
                                WatchGoKart(isPlayer: false, speed: gameState.pooRacer.speed)
                                    .scaleEffect(0.8)
                                Spacer()
                            } else {
                                Spacer()
                                WatchGoKart(isPlayer: false, speed: gameState.pooRacer.speed)
                                    .scaleEffect(0.8)
                            }
                        }
                        .frame(width: geometry.size.width * 0.6)
                        .offset(y: pooOffset)
                        .padding(.bottom, 40)
                    }
                }
                
                // HUD
                VStack {
                    HStack {
                        Text("\(Int(gameState.playerRacer.position / 5))%")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        // Mini speedometer
                        WatchSpeedometerView(speed: gameState.playerRacer.realSpeed)
                            .frame(width: 40, height: 40)
                        
                        Spacer()
                        
                        Text("\(Int(gameState.pooRacer.position / 5))%")
                            .font(.caption2)
                            .foregroundColor(.brown)
                    }
                    .padding(5)
                    
                    Spacer()
                    
                    // Tap zones
                    HStack(spacing: 2) {
                        Button(action: { gameState.tapLeft() }) {
                            VStack {
                                Image(systemName: "arrow.left")
                                    .font(.caption2)
                                Color.blue.opacity(0.3)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { gameState.brake() }) {
                            VStack {
                                Image(systemName: "octagon.fill")
                                    .font(.caption2)
                                Color.red.opacity(0.3)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { gameState.tapRight() }) {
                            VStack {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Color.blue.opacity(0.3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: 30)
                }
            }
        }
        .focusable()
        .digitalCrownRotation($scrollAmount, from: 0, through: 1000, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: scrollAmount) { newValue in
            gameState.onCrownRotate(delta: newValue - previousScrollAmount)
            previousScrollAmount = newValue
        }
        .onAppear {
            scrollAmount = 0
            previousScrollAmount = 0
        }
    }
    
    // Calculate turn amount based on race progress (turn happens between 200-350)
    func getTurnAmount(progress: CGFloat) -> CGFloat {
        if progress < 200 {
            return 0
        } else if progress < 275 {
            return (progress - 200) / 75.0
        } else if progress < 350 {
            return 1.0 - (progress - 275) / 75.0
        } else {
            return 0
        }
    }
}

// MARK: - Go Kart View

struct WatchGoKart: View {
    let isPlayer: Bool
    let speed: CGFloat
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 35, height: 8)
                .offset(y: 15)
            
            // Main kart body
            RoundedRectangle(cornerRadius: 4)
                .fill(isPlayer ? Color.blue : Color.brown)
                .frame(width: 30, height: 20)
            
            // Driver
            Text(isPlayer ? "🧑" : "💩")
                .font(.system(size: 18))
                .offset(y: -3)
            
            // Wheels (simple circles)
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .offset(x: -10, y: 8)
            
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .offset(x: 10, y: 8)
            
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .offset(x: -10, y: -2)
            
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .offset(x: 10, y: -2)
        }
        .frame(width: 35, height: 30)
    }
}

// MARK: - Finish View

struct WatchFinishView: View {
    @ObservedObject var gameState: WatchRaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 10) {
            if let crashType = gameState.crashType {
                // Crash scenario
                if crashType == .wall {
                    Text("💥 CRASH!")
                        .font(.title3)
                        .foregroundColor(.red)
                    
                    if gameState.winner == "You" {
                        Text("Poo hit wall!")
                            .font(.caption2)
                        Text("You win! 🏆")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("You hit wall!")
                            .font(.caption2)
                        Text("Poo wins! 💩")
                            .font(.caption)
                            .foregroundColor(.brown)
                    }
                } else {
                    Text("💥 CRASH!")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("Racers collided!")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    
                    if gameState.winner == "You" {
                        Text("You were ahead! 🏆")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Poo was ahead! 💩")
                            .font(.caption)
                            .foregroundColor(.brown)
                    }
                }
            } else {
                // Normal finish
                if gameState.winner == "You" {
                    Text("🏆 WIN! 🏆")
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text("You won!")
                        .font(.caption)
                } else {
                    Text("💩 POO WINS")
                        .font(.title3)
                        .foregroundColor(.brown)
                    
                    Text("Poo beat you!")
                        .font(.caption)
                }
            }
            
            Button("AGAIN") {
                gameState.startRace()
            }
            .buttonStyle(.bordered)
            
            Button("HOME") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.brown)
        }
    }
}

// MARK: - Watch Speedometer

struct WatchSpeedometerView: View {
    let speed: CGFloat
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            // Speed arc (0-100 MPH)
            Circle()
                .trim(from: 0, to: min(speed / 100.0, 1.0))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .yellow, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: speed)
            
            // Center
            Text("\(Int(speed))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    RaceTheLooView()
}
