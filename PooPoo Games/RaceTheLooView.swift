//
//  RaceTheLooView.swift
//  PooPoo Games
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
        case .sCurve: return "S-Curve Circuit"
        case .hairpin: return "Hairpin Turn"
        case .chicane: return "Chicane Challenge"
        }
    }
    
    var description: String {
        switch self {
        case .straightaway: return "Classic straight track"
        case .sCurve: return "Winding S-curves"
        case .hairpin: return "Sharp hairpin turns"
        case .chicane: return "Quick left-right chicanes"
        }
    }
}

struct Racer {
    var position: CGFloat = 0  // 0 to 500 (finish line)
    var lanePosition: CGFloat = 0.5  // 0 = left, 0.5 = center, 1 = right
    var speed: CGFloat = 0
    var realSpeed: CGFloat = 0  // MPH for display
}

// MARK: - Game State

class RaceGameState: ObservableObject {
    enum GamePhase {
        case welcome, selectDifficulty, selectTrack, racing, finished
    }
    
    enum CrashType {
        case wall, collision
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var playerRacer = Racer()
    @Published var pooRacer = Racer()
    @Published var raceProgress: CGFloat = 0
    @Published var winner: String = ""
    @Published var selectedDifficulty: Difficulty = .medium
    @Published var selectedTrack: TrackType = .straightaway
    @Published var crashType: CrashType?
    
    private var gameTimer: Timer?
    private var aiTimer: Timer?
    
    func startRace() {
        playerRacer = Racer()
        pooRacer = Racer()
        raceProgress = 0
        winner = ""
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
        
        // Calculate real MPH (speed * 60 for better scale)
        playerRacer.realSpeed = playerRacer.speed * 60
        pooRacer.realSpeed = pooRacer.speed * 60
        
        // Decay speed (friction)
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
            // Both crash - whoever is ahead wins
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
        
        // Update race progress for camera
        raceProgress = max(playerRacer.position, pooRacer.position)
    }
    
    func checkWallCollision(racer: Racer) -> Bool {
        // Don't check wall collisions at the very start
        if racer.position < 10 {
            return false
        }
        
        // Get the current turn amount for the racer's position
        let turnAmount = getTurnAmountForPosition(progress: racer.position, trackType: selectedTrack)
        
        // Calculate the road boundaries at this position
        // Road goes from 0.25 to 0.75 with turn offset
        let roadLeftBoundary = 0.25 + turnAmount * 0.35
        let roadRightBoundary = 0.75 + turnAmount * 0.35
        
        // Lane positions are 0.3, 0.5, 0.7
        // Give more margin - only crash if WAY outside the road
        let racerLeft = racer.lanePosition - 0.15  // Increased from 0.1 for more forgiveness
        let racerRight = racer.lanePosition + 0.15
        
        // Add safety margin to road boundaries
        let safeLeftBoundary = roadLeftBoundary - 0.05
        let safeRightBoundary = roadRightBoundary + 0.05
        
        // Collision only if racer is significantly outside the road
        return racerLeft < safeLeftBoundary || racerRight > safeRightBoundary
    }
    
    func checkRacerCollision() -> Bool {
        // Don't check collisions until racers have moved apart (first 2 seconds of race)
        if playerRacer.position < 20 && pooRacer.position < 20 {
            return false
        }
        
        // Check if racers are close in position and in same lane
        let positionDiff = abs(playerRacer.position - pooRacer.position)
        let laneDiff = abs(playerRacer.lanePosition - pooRacer.lanePosition)
        
        // Collision only if they're within 5 units AND in exactly the same lane (not adjacent)
        return positionDiff < 5 && laneDiff < 0.15
    }
    
    func getTurnAmountForPosition(progress: CGFloat, trackType: TrackType) -> CGFloat {
        switch trackType {
        case .straightaway:
            if progress < 200 {
                return 0
            } else if progress < 275 {
                return (progress - 200) / 75.0
            } else if progress < 350 {
                return 1.0 - (progress - 275) / 75.0
            } else {
                return 0
            }
            
        case .sCurve:
            if progress < 100 {
                return 0
            } else if progress < 150 {
                return (progress - 100) / 50.0
            } else if progress < 200 {
                return 1.0 - (progress - 150) / 50.0
            } else if progress < 250 {
                return -((progress - 200) / 50.0)
            } else if progress < 300 {
                return -(1.0 - (progress - 250) / 50.0)
            } else if progress < 350 {
                return (progress - 300) / 50.0
            } else if progress < 400 {
                return 1.0 - (progress - 350) / 50.0
            } else {
                return 0
            }
            
        case .hairpin:
            if progress < 150 {
                return 0
            } else if progress < 220 {
                return ((progress - 150) / 70.0) * 1.5
            } else if progress < 280 {
                return 1.5
            } else if progress < 350 {
                return 1.5 - ((progress - 280) / 70.0) * 1.5
            } else {
                return 0
            }
            
        case .chicane:
            if progress < 120 {
                return 0
            } else if progress < 160 {
                return -((progress - 120) / 40.0) * 0.8
            } else if progress < 200 {
                return -0.8 + ((progress - 160) / 40.0) * 1.6
            } else if progress < 240 {
                return 0.8 - ((progress - 200) / 40.0) * 1.6
            } else if progress < 280 {
                return -0.8 + ((progress - 240) / 40.0) * 0.8
            } else if progress < 340 {
                return -((progress - 280) / 30.0) * 0.6
            } else if progress < 380 {
                return -0.6 + ((progress - 340) / 40.0) * 1.2
            } else if progress < 420 {
                return 0.6 - ((progress - 380) / 40.0) * 0.6
            } else {
                return 0
            }
        }
    }
    
    func updateAI() {
        // AI accelerates based on difficulty level (< not > so lower threshold = more acceleration)
        if Double.random(in: 0...1) < (1.0 - selectedDifficulty.aiAccelerationChance) {
            pooRacer.speed = min(pooRacer.speed + selectedDifficulty.aiAcceleration, selectedDifficulty.aiMaxSpeed)
        }
        
        // Smart lane selection based on track curves and player position
        let currentTurn = getTurnAmountForPosition(progress: pooRacer.position, trackType: selectedTrack)
        let positionDiff = abs(playerRacer.position - pooRacer.position)
        let isPlayerClose = positionDiff < 15
        
        // First priority: Avoid walls by staying in safe lanes during turns
        // More aggressive wall avoidance with better lane selection
        if abs(currentTurn) > 0.2 {  // Lower threshold for earlier detection
            // In a turn - always choose the safest lane
            if currentTurn > 0 {
                // Right turn - ALWAYS use left lane (0.3) which is furthest from right wall
                pooRacer.lanePosition = 0.3
            } else if currentTurn < 0 {
                // Left turn - ALWAYS use right lane (0.7) which is furthest from left wall
                pooRacer.lanePosition = 0.7
            }
        }
        // Second priority: Avoid player collision
        else if isPlayerClose && abs(playerRacer.lanePosition - pooRacer.lanePosition) < 0.2 {
            // Player is close and in same lane - move to different lane!
            let lanes: [CGFloat] = [0.3, 0.5, 0.7]
            let availableLanes = lanes.filter { abs($0 - playerRacer.lanePosition) > 0.15 }
            if !availableLanes.isEmpty {
                pooRacer.lanePosition = availableLanes.randomElement() ?? 0.5
            }
        }
        // Third priority: Stay in center on straights
        else if abs(currentTurn) < 0.1 {
            // On straight sections, prefer center lane for optimal positioning
            pooRacer.lanePosition = 0.5
        }
    }
    
    func accelerate() {
        playerRacer.speed = min(playerRacer.speed + 0.05, 1.5)
    }
    
    func brake() {
        playerRacer.speed = max(playerRacer.speed - 0.15, 0)
    }
    
    func steerLeft() {
        playerRacer.lanePosition = max(0.3, playerRacer.lanePosition - 0.2)
    }
    
    func steerRight() {
        playerRacer.lanePosition = min(0.7, playerRacer.lanePosition + 0.2)
    }
    
    func finishRace() {
        gamePhase = .finished
        gameTimer?.invalidate()
        aiTimer?.invalidate()
    }
}

// MARK: - Main View

struct RaceTheLooView: View {
    @StateObject private var gameState = RaceGameState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if gameState.gamePhase == .racing {
                    RacingView(gameState: gameState, geometry: geometry)
                } else if gameState.gamePhase == .finished {
                    FinishView(gameState: gameState, dismiss: dismiss)
                } else if gameState.gamePhase == .selectDifficulty {
                    DifficultySelectionView(gameState: gameState, dismiss: dismiss)
                } else if gameState.gamePhase == .selectTrack {
                    TrackSelectionView(gameState: gameState, dismiss: dismiss)
                } else {
                    WelcomeView(gameState: gameState, dismiss: dismiss)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Welcome Screen

struct WelcomeView: View {
    @ObservedObject var gameState: RaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("🏁 Race the Loo 🚽")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                
                Text("🏎️ vs 💩")
                    .font(.system(size: 60))
                
                Text("Race against Poo to reach the restroom first!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("START RACE") {
                    gameState.gamePhase = .selectDifficulty
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 250, height: 60)
                .background(Color.green)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Controls:")
                        .font(.headline)
                    Text("• Drag STEERING WHEEL left/right")
                    Text("• Press & hold GAS to accelerate")
                    Text("• Press BRAKE to slow down")
                }
                .foregroundColor(.secondary)
                
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
}

// MARK: - Difficulty Selection View

struct DifficultySelectionView: View {
    @ObservedObject var gameState: RaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Choose Difficulty")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                
                Text("🏁 Race the Loo 🚽")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    DifficultyButton(
                        difficulty: .easy,
                        icon: "😊",
                        color: .green,
                        gameState: gameState
                    )
                    
                    DifficultyButton(
                        difficulty: .medium,
                        icon: "😐",
                        color: .orange,
                        gameState: gameState
                    )
                    
                    DifficultyButton(
                        difficulty: .hard,
                        icon: "😰",
                        color: .red,
                        gameState: gameState
                    )
                }
                .padding()
                
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
}

struct DifficultyButton: View {
    let difficulty: Difficulty
    let icon: String
    let color: Color
    @ObservedObject var gameState: RaceGameState
    
    var body: some View {
        Button(action: {
            gameState.selectedDifficulty = difficulty
            gameState.gamePhase = .selectTrack
        }) {
            HStack(spacing: 15) {
                Text(icon)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(difficulty.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Poo speed: \(Int(difficulty.aiMaxSpeed * 60)) MPH")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(15)
        }
        .frame(width: 300)
    }
}

// MARK: - Track Selection View

struct TrackSelectionView: View {
    @ObservedObject var gameState: RaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Choose Track")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                
                Text("Difficulty: \(gameState.selectedDifficulty.displayName)")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(spacing: 20) {
                        TrackButton(
                            track: .straightaway,
                            icon: "→",
                            gameState: gameState
                        )
                        
                        TrackButton(
                            track: .sCurve,
                            icon: "〰️",
                            gameState: gameState
                        )
                        
                        TrackButton(
                            track: .hairpin,
                            icon: "↪️",
                            gameState: gameState
                        )
                        
                        TrackButton(
                            track: .chicane,
                            icon: "⚡️",
                            gameState: gameState
                        )
                    }
                    .padding()
                }
                
                Button("BACK") {
                    gameState.gamePhase = .selectDifficulty
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.brown)
                .cornerRadius(10)
            }
        }
    }
}

struct TrackButton: View {
    let track: TrackType
    let icon: String
    @ObservedObject var gameState: RaceGameState
    
    var body: some View {
        Button(action: {
            gameState.selectedTrack = track
            gameState.startRace()
        }) {
            HStack(spacing: 15) {
                Text(icon)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(track.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(track.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
        }
        .frame(width: 320)
    }
}

// MARK: - Racing View

struct RacingView: View {
    @ObservedObject var gameState: RaceGameState
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.7, blue: 1.0),
                    Color(red: 0.7, green: 0.85, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            
            // Road with perspective
            GeometryReader { geo in
                RoadView(raceProgress: gameState.raceProgress, trackType: gameState.selectedTrack)
                
                // Finish line
                if gameState.raceProgress > 85 {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .black, .white, .black]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 30)
                        
                        Text("🚽 FINISH 🚽")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .offset(y: geo.size.height * 0.2)
                }
                
                // Player kart
                GoKartView(isPlayer: true, speed: gameState.playerRacer.speed)
                    .offset(
                        x: geo.size.width * gameState.playerRacer.lanePosition - 30,
                        y: geo.size.height * 0.7
                    )
                
                // Poo kart (relative position)
                let pooY = geo.size.height * 0.7 - (gameState.pooRacer.position - gameState.playerRacer.position) * 5
                if pooY > 0 && pooY < geo.size.height {
                    GoKartView(isPlayer: false, speed: gameState.pooRacer.speed)
                        .offset(
                            x: geo.size.width * gameState.pooRacer.lanePosition - 30,
                            y: pooY
                        )
                }
            }
            
            // HUD
            VStack {
                HStack {
                    Button(action: { gameState.gamePhase = .welcome }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .padding(12)
                            .background(Color.brown.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("You: \(Int(gameState.playerRacer.position / 5))%")
                            .foregroundColor(.green)
                        Text("Poo: \(Int(gameState.pooRacer.position / 5))%")
                            .foregroundColor(.brown)
                    }
                    .font(.headline)
                    .padding(10)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
                
                // Speedometer
                SpeedometerView(speed: gameState.playerRacer.realSpeed)
                    .frame(width: 120, height: 120)
                    .padding(.bottom, 10)
                
                // Controls
                VStack(spacing: 15) {
                    HStack(spacing: 40) {
                        // Interactive Steering Wheel
                        SteeringWheelView(gameState: gameState)
                            .frame(width: 100, height: 100)
                        
                        Spacer()
                        
                        // Brake and Gas pedals (vertical stack)
                        VStack(spacing: 15) {
                            // Brake button (on top)
                            Button(action: { gameState.brake() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 70, height: 70)
                                    
                                    VStack(spacing: 2) {
                                        Text("BRAKE")
                                            .font(.system(size: 10))
                                            .fontWeight(.bold)
                                        Image(systemName: "octagon.fill")
                                            .font(.system(size: 22))
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            
                            // Gas pedal - Press and hold (below brake)
                            GasPedalView(gameState: gameState)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Gas Pedal View

struct GasPedalView: View {
    @ObservedObject var gameState: RaceGameState
    @State private var isPressed = false
    @State private var accelerationTimer: Timer?
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? Color.green.opacity(0.8) : Color.green)
                .frame(width: 80, height: 80)
                .scaleEffect(isPressed ? 0.95 : 1.0)
            
            VStack(spacing: 2) {
                Text("GAS")
                    .font(.caption)
                    .fontWeight(.bold)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .foregroundColor(.white)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        startAccelerating()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    stopAccelerating()
                }
        )
        .onDisappear {
            stopAccelerating()
        }
    }
    
    func startAccelerating() {
        // Make sure any previous timer is stopped
        accelerationTimer?.invalidate()
        accelerationTimer = nil
        
        // Start new timer
        accelerationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            gameState.accelerate()
        }
    }
    
    func stopAccelerating() {
        accelerationTimer?.invalidate()
        accelerationTimer = nil
    }
}

// MARK: - Steering Wheel View

struct SteeringWheelView: View {
    @ObservedObject var gameState: RaceGameState
    @State private var wheelAngle: Double = 0
    @State private var dragStartAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Outer wheel rim
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray, Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )
                .shadow(color: .black.opacity(0.5), radius: 5)
            
            // Inner grip texture
            Circle()
                .stroke(Color(red: 0.2, green: 0.2, blue: 0.2), lineWidth: 8)
                .padding(10)
            
            // Spokes
            ForEach(0..<3) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.black]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: 8)
                    .offset(x: 0)
                    .rotationEffect(.degrees(Double(i) * 120 + wheelAngle))
            }
            
            // Center hub
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.gray, Color.black]),
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 35, height: 35)
                )
            
            // Top indicator mark
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .offset(y: -55)
                .rotationEffect(.degrees(wheelAngle))
            
            // Direction indicators
            if abs(wheelAngle) > 5 {
                Image(systemName: wheelAngle < 0 ? "arrow.left" : "arrow.right")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(wheelAngle < 0 ? .blue : .blue)
                    .offset(y: -80)
            }
        }
        .rotationEffect(.degrees(wheelAngle))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let center = CGPoint(x: 70, y: 70)
                    let vector = CGPoint(
                        x: value.location.x - center.x,
                        y: value.location.y - center.y
                    )
                    
                    var angle = atan2(vector.y, vector.x) * 180 / .pi
                    angle = angle + 90
                    
                    // Limit rotation to -90 to +90 degrees
                    wheelAngle = max(-90, min(90, angle))
                    
                    // Update lane position based on wheel angle
                    if wheelAngle < -20 {
                        gameState.playerRacer.lanePosition = 0.3
                    } else if wheelAngle > 20 {
                        gameState.playerRacer.lanePosition = 0.7
                    } else {
                        gameState.playerRacer.lanePosition = 0.5
                    }
                }
                .onEnded { _ in
                    // Spring back to center
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        wheelAngle = 0
                    }
                }
        )
    }
}

// MARK: - Road View

struct RoadView: View {
    let raceProgress: CGFloat
    let trackType: TrackType
    
    init(raceProgress: CGFloat, trackType: TrackType = .straightaway) {
        self.raceProgress = raceProgress
        self.trackType = trackType
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Green grass background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 0.2),
                        Color(red: 0.3, green: 0.7, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Grandstands (left side)
                if raceProgress < 200 {
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { i in
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.white]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 30, height: 80)
                                .offset(x: -geometry.size.width * 0.35, y: -geometry.size.height * 0.3)
                        }
                    }
                }
                
                // Grandstands (right side)
                if raceProgress < 200 {
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { i in
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.white]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .frame(width: 30, height: 80)
                                .offset(x: geometry.size.width * 0.35, y: -geometry.size.height * 0.3)
                        }
                    }
                }
                
                // Determine turn amount based on progress
                let turnAmount = getTurnAmount(progress: raceProgress, trackType: trackType)
                
                // Road with turn
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // Road shifts based on turn amount (increased multiplier for dramatic curves)
                    let leftEdge = 0.25 + turnAmount * 0.35
                    let rightEdge = 0.75 + turnAmount * 0.35
                    
                    path.move(to: CGPoint(x: width * leftEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.4 + turnAmount * 0.25), y: 0))
                    path.addLine(to: CGPoint(x: width * (0.6 + turnAmount * 0.25), y: 0))
                    path.addLine(to: CGPoint(x: width * rightEdge, y: height))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                
                // Road edges (white lines)
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let leftEdge = 0.25 + turnAmount * 0.35
                    let rightEdge = 0.75 + turnAmount * 0.35
                    
                    // Left edge
                    path.move(to: CGPoint(x: width * leftEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.4 + turnAmount * 0.25), y: 0))
                    
                    // Right edge
                    path.move(to: CGPoint(x: width * rightEdge, y: height))
                    path.addLine(to: CGPoint(x: width * (0.6 + turnAmount * 0.25), y: 0))
                }
                .stroke(Color.white, lineWidth: 4)
                
                // Red/white curbing on edges
                Canvas { context, size in
                    for i in 0..<20 {
                        let progress = CGFloat(i) / 20.0
                        let y = size.height - (progress * size.height)
                        let leftEdge = 0.25 + turnAmount * 0.35
                        let rightEdge = 0.75 + turnAmount * 0.35
                        let topLeftX = 0.4 + turnAmount * 0.25
                        let topRightX = 0.6 + turnAmount * 0.25
                        
                        if y >= 0 && y <= size.height {
                            let leftX = size.width * (leftEdge + (topLeftX - leftEdge) * progress)
                            let rightX = size.width * (rightEdge + (topRightX - rightEdge) * progress)
                            
                            // Alternating red/white curbing
                            let color: Color = (i + Int(raceProgress / 10)) % 2 == 0 ? .red : .white
                            
                            // Left curb
                            let leftRect = Rectangle()
                                .path(in: CGRect(x: leftX - 8, y: y, width: 8, height: size.height / 20))
                            context.fill(leftRect, with: .color(color))
                            
                            // Right curb
                            let rightRect = Rectangle()
                                .path(in: CGRect(x: rightX, y: y, width: 8, height: size.height / 20))
                            context.fill(rightRect, with: .color(color))
                        }
                    }
                }
                
                // Center yellow dashed lines
                Canvas { context, size in
                    for i in 0..<15 {
                        let progress = CGFloat(i) / 15.0
                        let offset = raceProgress.truncatingRemainder(dividingBy: 20)
                        let y = size.height - (progress * size.height) + offset * 5
                        
                        if y >= 0 && y <= size.height {
                            let lineWidth = 4 + (1 - progress) * 8
                            let centerX = 0.5 + turnAmount * 0.25 * progress
                            
                            let rect = Rectangle()
                                .path(in: CGRect(
                                    x: size.width * centerX - lineWidth / 2,
                                    y: y,
                                    width: lineWidth,
                                    height: 25 * (1 - progress * 0.6)
                                ))
                            
                            context.fill(rect, with: .color(.yellow))
                        }
                    }
                }
                
                // Start/Finish line (checkered flag pattern)
                if raceProgress < 20 || raceProgress > 480 {
                    Canvas { context, size in
                        let lineY = raceProgress < 20 ? size.height * 0.7 : size.height * 0.3
                        let leftEdge = 0.25 + turnAmount * 0.35
                        let rightEdge = 0.75 + turnAmount * 0.35
                        
                        for x in 0..<20 {
                            for y in 0..<3 {
                                let isBlack = (x + y) % 2 == 0
                                let rect = Rectangle()
                                    .path(in: CGRect(
                                        x: size.width * leftEdge + CGFloat(x) * (size.width * (rightEdge - leftEdge)) / 20,
                                        y: lineY + CGFloat(y) * 10,
                                        width: (size.width * (rightEdge - leftEdge)) / 20,
                                        height: 10
                                    ))
                                context.fill(rect, with: .color(isBlack ? .black : .white))
                            }
                        }
                    }
                }
                
                // Trees along the track
                ForEach(0..<10, id: \.self) { i in
                    let treeProgress = CGFloat(i) / 10.0
                    let treeY = geometry.size.height * (1 - treeProgress)
                    let treeScale = 1.0 - treeProgress * 0.7
                    
                    // Left trees
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.1, green: 0.5, blue: 0.1))
                            .frame(width: 40 * treeScale, height: 40 * treeScale)
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0))
                            .frame(width: 10 * treeScale, height: 20 * treeScale)
                            .offset(y: 10 * treeScale)
                    }
                    .position(x: geometry.size.width * 0.1, y: treeY)
                    
                    // Right trees
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.1, green: 0.5, blue: 0.1))
                            .frame(width: 40 * treeScale, height: 40 * treeScale)
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.2, blue: 0))
                            .frame(width: 10 * treeScale, height: 20 * treeScale)
                            .offset(y: 10 * treeScale)
                    }
                    .position(x: geometry.size.width * 0.9, y: treeY)
                }
            }
        }
    }
    
    // Calculate turn amount based on race progress and track type
    func getTurnAmount(progress: CGFloat, trackType: TrackType) -> CGFloat {
        switch trackType {
        case .straightaway:
            // Original single right turn
            if progress < 200 {
                return 0
            } else if progress < 275 {
                return (progress - 200) / 75.0
            } else if progress < 350 {
                return 1.0 - (progress - 275) / 75.0
            } else {
                return 0
            }
            
        case .sCurve:
            // S-curve: right then left then right
            if progress < 100 {
                return 0
            } else if progress < 150 {
                // Right turn
                return (progress - 100) / 50.0
            } else if progress < 200 {
                // Transition to left
                return 1.0 - (progress - 150) / 50.0
            } else if progress < 250 {
                // Left turn (negative)
                return -((progress - 200) / 50.0)
            } else if progress < 300 {
                // Transition back
                return -(1.0 - (progress - 250) / 50.0)
            } else if progress < 350 {
                // Final right turn
                return (progress - 300) / 50.0
            } else if progress < 400 {
                return 1.0 - (progress - 350) / 50.0
            } else {
                return 0
            }
            
        case .hairpin:
            // Sharp hairpin turn
            if progress < 150 {
                return 0
            } else if progress < 220 {
                // Sharp right turn (stronger curve)
                return ((progress - 150) / 70.0) * 1.5
            } else if progress < 280 {
                // Hold the turn
                return 1.5
            } else if progress < 350 {
                // Exit turn
                return 1.5 - ((progress - 280) / 70.0) * 1.5
            } else {
                return 0
            }
            
        case .chicane:
            // Quick left-right-left chicane
            if progress < 120 {
                return 0
            } else if progress < 160 {
                // Quick left
                return -((progress - 120) / 40.0) * 0.8
            } else if progress < 200 {
                // Quick right
                return -0.8 + ((progress - 160) / 40.0) * 1.6
            } else if progress < 240 {
                // Quick left again
                return 0.8 - ((progress - 200) / 40.0) * 1.6
            } else if progress < 280 {
                // Back to center
                return -0.8 + ((progress - 240) / 40.0) * 0.8
            } else if progress < 340 {
                // Another chicane
                return -((progress - 280) / 30.0) * 0.6
            } else if progress < 380 {
                return -0.6 + ((progress - 340) / 40.0) * 1.2
            } else if progress < 420 {
                return 0.6 - ((progress - 380) / 40.0) * 0.6
            } else {
                return 0
            }
        }
    }
}

// MARK: - Go Kart View

struct GoKartView: View {
    let isPlayer: Bool
    let speed: CGFloat
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 70, height: 15)
                .offset(y: 30)
                .blur(radius: 2)
            
            // Main kart body
            RoundedRectangle(cornerRadius: 8)
                .fill(isPlayer ? Color.blue : Color.brown)
                .frame(width: 60, height: 40)
            
            // Driver (person or poo emoji)
            Text(isPlayer ? "🧑" : "💩")
                .font(.system(size: 30))
                .offset(y: -5)
            
            // Wheels (simple circles, no rotation)
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .offset(x: -22, y: 15)
            
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .offset(x: 22, y: 15)
            
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .offset(x: -22, y: -5)
            
            Circle()
                .fill(Color.black)
                .frame(width: 14, height: 14)
                .offset(x: 22, y: -5)
        }
        .frame(width: 70, height: 60)
    }
}

// MARK: - Finish View

struct FinishView: View {
    @ObservedObject var gameState: RaceGameState
    let dismiss: DismissAction
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                if let crashType = gameState.crashType {
                    // Crash scenario
                    if crashType == .wall {
                        Text("💥 CRASH! 💥")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.red)
                        
                        if gameState.winner == "You" {
                            Text("Poo hit the wall!")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("You win by default! 🏆")
                                .font(.title3)
                                .foregroundColor(.green)
                        } else {
                            Text("You crashed into the wall!")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Poo wins! 💩")
                                .font(.title3)
                                .foregroundColor(.brown)
                        }
                    } else {
                        // Collision
                        Text("💥 COLLISION! 💥")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("The racers crashed into each other!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if gameState.winner == "You" {
                            Text("You were ahead! 🏆")
                                .font(.title3)
                                .foregroundColor(.green)
                        } else {
                            Text("Poo was ahead! 💩")
                                .font(.title3)
                                .foregroundColor(.brown)
                        }
                    }
                } else {
                    // Normal finish
                    if gameState.winner == "You" {
                        Text("🏆 YOU WIN! 🏆")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.green)
                        
                        Text("You reached the restroom first!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("💩 POO WINS! 💩")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.brown)
                        
                        Text("The poo beat you to the toilet!")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("RACE AGAIN") {
                    gameState.startRace()
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
}

// MARK: - Speedometer View

struct SpeedometerView: View {
    let speed: CGFloat
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            // Speed arc (0-100 MPH)
            Circle()
                .trim(from: 0, to: min(speed / 100.0, 1.0))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.2), value: speed)
            
            // Center
            VStack(spacing: 2) {
                Text("\(Int(speed))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("MPH")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 80, height: 80)
            )
        }
    }
}

#Preview {
    RaceTheLooView()
}
