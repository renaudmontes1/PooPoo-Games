//
//  PooSpaceBattleView.swift
//  PooPoo Games
//
//  Created by Admin on 10/18/25.
//

import SwiftUI
import Combine

// Color extension for dark gray
extension Color {
    static let darkGray = Color(red: 0.3, green: 0.3, blue: 0.3)
}

// Weapon types
enum WeaponType {
    case machineGun
    case yokeShooter
}

// Enemy Poo
struct PooEnemy: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var velocity: CGFloat = 1.0
    var isDying: Bool = false
    var deathAnimationProgress: Double = 0.0
}

// Bullet
struct Bullet: Identifiable {
    let id = UUID()
    var position: CGPoint
    let weaponType: WeaponType
    let isEnemyBullet: Bool
}

// Game State
class SpaceBattleState: ObservableObject {
    enum GamePhase {
        case welcome
        case playing
        case gameOver
    }
    
    @Published var gamePhase: GamePhase = .welcome
    @Published var playerPosition: CGFloat = 0
    @Published var enemies: [PooEnemy] = []
    @Published var bullets: [Bullet] = []
    @Published var score: Int = 0
    @Published var lives: Int = 3
    @Published var selectedWeapon: WeaponType = .machineGun
    @Published var aimPosition: CGFloat = 0
    @Published var isAiming: Bool = false
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
    private var enemySpawnTimer: Timer?
    private var bulletTimer: Timer?
    private var direction: CGFloat = 1.0
    private var enemyShootCounter: Int = 0
    
    func selectWeapon(_ weapon: WeaponType) {
        selectedWeapon = weapon
        gamePhase = .playing
        startGame()
    }
    
    func startGame() {
        gamePhase = .playing
        selectedWeapon = .machineGun
        score = 0
        lives = 3
        enemies = []
        bullets = []
        playerPosition = screenBounds.midX
        aimPosition = screenBounds.midX
        isAiming = false
        direction = 1.0
        
        spawnEnemyWave()
        startGameLoop()
    }
    
    func spawnEnemyWave() {
        let rows = 3
        let cols = 5
        let spacing: CGFloat = 50
        let startY: CGFloat = 80
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * spacing + 40
                let y = startY + CGFloat(row) * spacing
                enemies.append(PooEnemy(position: CGPoint(x: x, y: y), size: 30))
            }
        }
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }
    
    func updateGame() {
        // Update death animations
        for i in 0..<enemies.count {
            if enemies[i].isDying {
                enemies[i].deathAnimationProgress += 0.05
            }
        }
        
        // Remove fully dead enemies
        enemies.removeAll { $0.isDying && $0.deathAnimationProgress >= 1.0 }
        
        // Move enemies
        var shouldReverse = false
        for i in 0..<enemies.count where !enemies[i].isDying {
            enemies[i].position.x += direction * enemies[i].velocity
            
            if enemies[i].position.x <= 20 || enemies[i].position.x >= screenBounds.width - 20 {
                shouldReverse = true
            }
        }
        
        if shouldReverse {
            direction *= -1
            for i in 0..<enemies.count where !enemies[i].isDying {
                enemies[i].position.y += 10
            }
        }
        
        // Enemy shooting
        enemyShootCounter += 1
        if enemyShootCounter >= 60 && !enemies.isEmpty { // Shoot every second
            enemyShootCounter = 0
            if let randomEnemy = enemies.randomElement() {
                enemyShoot(from: randomEnemy.position)
            }
        }
        
        // Move bullets
        for i in 0..<bullets.count {
            if bullets[i].isEnemyBullet {
                bullets[i].position.y += 8 // Enemy bullets move down fast
            } else {
                bullets[i].position.y -= 15 // Player bullets move up very fast
            }
        }
        
        // Remove off-screen bullets
        bullets.removeAll { bullet in
            bullet.position.y < 0 || bullet.position.y > screenBounds.height
        }
        
        // Check collisions
        checkCollisions()
        checkPlayerHit()
        
        // Check if enemies reached bottom
        if enemies.contains(where: { $0.position.y > screenBounds.height - 100 }) {
            gameOver()
        }
        
        // Spawn new wave if all enemies destroyed
        if enemies.isEmpty {
            spawnEnemyWave()
        }
    }
    
    func checkCollisions() {
        var bulletsToRemove: [UUID] = []
        var enemiesToUpdate: [(index: Int, action: EnemyAction)] = []
        
        for bullet in bullets where !bullet.isEnemyBullet {
            if bulletsToRemove.contains(bullet.id) { continue }
            
            for (index, enemy) in enemies.enumerated() where !enemy.isDying {
                let distance = hypot(bullet.position.x - enemy.position.x, bullet.position.y - enemy.position.y)
                if distance < enemy.size / 2 {
                    // Hit!
                    bulletsToRemove.append(bullet.id)
                    
                    // Machine gun kills poo immediately
                    if bullet.weaponType == .machineGun {
                        enemiesToUpdate.append((index: index, action: .die))
                        score += 10
                    }
                    // Yoke shooter splits poo into two smaller ones
                    else if bullet.weaponType == .yokeShooter {
                        if enemy.size > 15 {
                            enemiesToUpdate.append((index: index, action: .split))
                        } else {
                            // Too small to split, just kill it
                            enemiesToUpdate.append((index: index, action: .die))
                        }
                        score += 10
                    }
                    
                    break
                }
            }
        }
        
        // Remove bullets
        bullets.removeAll { bulletsToRemove.contains($0.id) }
        
        // Process enemy updates from highest index to lowest (to prevent index issues)
        for update in enemiesToUpdate.sorted(by: { $0.index > $1.index }) {
            switch update.action {
            case .die:
                enemies[update.index].isDying = true
            case .split:
                let enemy = enemies[update.index]
                let newSize = enemy.size * 0.6
                enemies.append(PooEnemy(position: CGPoint(x: enemy.position.x - 15, y: enemy.position.y), size: newSize, velocity: enemy.velocity * 1.2))
                enemies.append(PooEnemy(position: CGPoint(x: enemy.position.x + 15, y: enemy.position.y), size: newSize, velocity: enemy.velocity * 1.2))
                enemies[update.index].isDying = true
            }
        }
    }
    
    enum EnemyAction {
        case die
        case split
    }
    
    func checkPlayerHit() {
        for bullet in bullets where bullet.isEnemyBullet {
            let distance = hypot(bullet.position.x - playerPosition, bullet.position.y - (screenBounds.height - 60))
            if distance < 30 {
                if let bulletIndex = bullets.firstIndex(where: { $0.id == bullet.id }) {
                    bullets.remove(at: bulletIndex)
                }
                lives -= 1
                if lives <= 0 {
                    gameOver()
                }
                break
            }
        }
    }
    
    func shoot() {
        let shootX = isAiming ? aimPosition : playerPosition
        bullets.append(Bullet(position: CGPoint(x: shootX, y: screenBounds.height - 80), weaponType: selectedWeapon, isEnemyBullet: false))
        isAiming = false
    }
    
    func enemyShoot(from position: CGPoint) {
        bullets.append(Bullet(position: position, weaponType: .machineGun, isEnemyBullet: true))
    }
    
    func startAiming(at position: CGFloat) {
        isAiming = true
        aimPosition = max(30, min(screenBounds.width - 30, position))
    }
    
    func updateAim(to position: CGFloat) {
        aimPosition = max(30, min(screenBounds.width - 30, position))
    }
    
    func cancelAiming() {
        isAiming = false
    }
    
    func movePlayer(to position: CGFloat) {
        playerPosition = max(30, min(screenBounds.width - 30, position))
    }
    
    func gameOver() {
        gamePhase = .gameOver
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    func backToWelcome() {
        gamePhase = .welcome
        gameTimer?.invalidate()
        gameTimer = nil
    }
}

struct PooSpaceBattleView: View {
    @StateObject private var gameState = SpaceBattleState()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Starfield background
                Color.black
                    .ignoresSafeArea()
                
                // Stars
                ForEach(0..<50, id: \.self) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
                
                if gameState.gamePhase == .welcome {
                    // Welcome Screen
                    VStack(spacing: 30) {
                        Text("🚀 POO SPACE BATTLE 💩")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                        
                        Text("Defend Earth from\nthe Poo Invasion!")
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button("START") {
                            gameState.startGame()
                        }
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
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
                    // Game Over Screen
                    VStack(spacing: 30) {
                        Text("GAME OVER")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                        
                        Text("SCORE: \(gameState.score)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        
                        Button("PLAY AGAIN") {
                            gameState.startGame()
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
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
                    // Playing
                    VStack {
                        // HUD
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
                            
                            Text("SCORE: \(gameState.score)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            HStack(spacing: 5) {
                                ForEach(0..<gameState.lives, id: \.self) { _ in
                                    Text("❤️")
                                        .font(.system(size: 20))
                                }
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Aiming line
                        if gameState.isAiming {
                            Path { path in
                                path.move(to: CGPoint(x: gameState.aimPosition, y: geometry.size.height - 80))
                                path.addLine(to: CGPoint(x: gameState.aimPosition, y: 0))
                            }
                            .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                                .frame(width: 30, height: 30)
                                .position(x: gameState.aimPosition, y: 50)
                        }
                        
                        // Enemies
                        ForEach(gameState.enemies) { enemy in
                            PixelatedPoo(size: enemy.size, deathProgress: enemy.isDying ? enemy.deathAnimationProgress : 0)
                                .position(enemy.position)
                                .opacity(enemy.isDying ? 1.0 - enemy.deathAnimationProgress : 1.0)
                        }
                        
                        // Bullets
                        ForEach(gameState.bullets) { bullet in
                            if bullet.isEnemyBullet {
                                // Enemy bullet (red)
                                Capsule()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 12)
                                    .position(bullet.position)
                            } else {
                                // Player bullet
                                Capsule()
                                    .fill(bullet.weaponType == .machineGun ? Color.yellow : Color.orange)
                                    .frame(width: 4, height: 12)
                                    .position(bullet.position)
                            }
                        }
                        
                        Spacer()
                        
                        // Player ship with visible gun
                        ZStack {
                            // The ship
                            Text("🚀")
                                .font(.system(size: 40))
                            
                            // The gun barrel on top
                            if gameState.selectedWeapon == .machineGun {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 4, height: 20)
                                    .offset(y: -25)
                                
                                Circle()
                                    .fill(Color.darkGray)
                                    .frame(width: 8, height: 8)
                                    .offset(y: -35)
                            } else {
                                // Yoke shooter (wider barrel)
                                Capsule()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 20)
                                    .offset(y: -25)
                                
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 10, height: 10)
                                    .offset(y: -35)
                            }
                        }
                        .position(x: gameState.playerPosition, y: geometry.size.height - 60)
                        
                        // Fire button
                        Button(action: { gameState.shoot() }) {
                            Text("FIRE")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(width: 120, height: 50)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
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
                            // Move player with drag
                            gameState.movePlayer(to: value.location.x)
                            // If dragging in upper area, start aiming
                            if value.location.y < geometry.size.height - 150 {
                                gameState.startAiming(at: value.location.x)
                            } else {
                                gameState.cancelAiming()
                            }
                        }
                    }
                    .onEnded { _ in
                        if gameState.gamePhase == .playing {
                            gameState.cancelAiming()
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Pixelated Poo View (8-bit style)
struct PixelatedPoo: View {
    let size: CGFloat
    let deathProgress: Double
    
    var body: some View {
        let pixelSize = size / 8
        
        Canvas { context, canvasSize in
            // Brown color palette
            let darkBrown = Color(red: 0.4, green: 0.2, blue: 0.1)
            let mediumBrown = Color(red: 0.55, green: 0.27, blue: 0.07)
            let lightBrown = Color(red: 0.65, green: 0.35, blue: 0.15)
            
            // Poo shape pattern (8x8 grid)
            let pattern: [[Int]] = [
                [0, 0, 0, 1, 1, 0, 0, 0],
                [0, 0, 1, 2, 2, 1, 0, 0],
                [0, 1, 2, 2, 2, 2, 1, 0],
                [0, 1, 2, 3, 3, 2, 1, 0],
                [1, 2, 2, 3, 3, 2, 2, 1],
                [1, 2, 2, 2, 2, 2, 2, 1],
                [0, 1, 2, 2, 2, 2, 1, 0],
                [0, 0, 1, 1, 1, 1, 0, 0]
            ]
            
            for (y, row) in pattern.enumerated() {
                for (x, pixel) in row.enumerated() {
                    if pixel > 0 {
                        var color: Color
                        switch pixel {
                        case 1: color = darkBrown
                        case 2: color = mediumBrown
                        case 3: color = lightBrown
                        default: color = darkBrown
                        }
                        
                        // Death animation - fade to black and shrink
                        if deathProgress > 0 {
                            color = color.opacity(1.0 - deathProgress)
                        }
                        
                        // Random offset during death for explosion effect
                        let offsetX = deathProgress > 0 ? CGFloat.random(in: -deathProgress * 3...deathProgress * 3) : 0
                        let offsetY = deathProgress > 0 ? CGFloat.random(in: -deathProgress * 3...deathProgress * 3) : 0
                        
                        let rect = CGRect(
                            x: CGFloat(x) * pixelSize + offsetX,
                            y: CGFloat(y) * pixelSize + offsetY,
                            width: pixelSize,
                            height: pixelSize
                        )
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    PooSpaceBattleView()
}
