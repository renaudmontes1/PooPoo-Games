//
//  RaceTheLooView.swift
//  PooPoo Games Watch App
//
//  Created by Emilio Montes on 10/18/25.
//

import SwiftUI

//
//  RaceTheLooView.swift
//  PooPoo Games Watch App
//
//  Created by Emilio Montes on 10/18/25.
//

import SwiftUI
import Combine

// MARK: - Models

struct WatchRacer {
    var position: CGFloat = 0  // 0 to 500
    var lanePosition: CGFloat = 0.5  // 0.3 = left, 0.7 = right
    var speed: CGFloat = 0
    var realSpeed: CGFloat = 0  // MPH for display
}

// MARK: - Game State

class WatchRaceGameState: ObservableObject {
    enum GamePhase {
        case welcome, racing, finished
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var playerRacer = WatchRacer()
    @Published var pooRacer = WatchRacer()
    @Published var winner: String = ""
    @Published var crownValue: Double = 0
    
    private var gameTimer: Timer?
    private var aiTimer: Timer?
    
    func startRace() {
        playerRacer = WatchRacer()
        pooRacer = WatchRacer()
        winner = ""
        crownValue = 0
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
        
        // Check for winner
        if playerRacer.position >= 500 {
            winner = "You"
            finishRace()
        } else if pooRacer.position >= 500 {
            winner = "Poo"
            finishRace()
        }
    }
    
    func updateAI() {
        if Double.random(in: 0...1) > 0.4 {
            pooRacer.speed = min(pooRacer.speed + 0.05, 0.9)
        }
        
        if Double.random(in: 0...1) > 0.7 {
            pooRacer.lanePosition = Bool.random() ? 0.3 : 0.7
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
        playerRacer.speed = max(playerRacer.speed - 0.25, 0)
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
                gameState.startRace()
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
