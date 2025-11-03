//
//  PooSpaceBattleView.swift
//  PooPoo Games Watch App
//
//  Created by Emilio Montes on 10/18/25.
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
    var velocity: CGFloat = 0.5
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
    
    var screenBounds: CGRect = .zero
    private var gameTimer: Timer?
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
        direction = 1.0
        
        spawnEnemyWave()
        startGameLoop()
    }
    
    func spawnEnemyWave() {
        let rows = 2
        let cols = 3
        let spacing: CGFloat = 35
        let startY: CGFloat = 40
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = CGFloat(col) * spacing + 30
                let y = startY + CGFloat(row) * spacing
                enemies.append(PooEnemy(position: CGPoint(x: x, y: y), size: 18))
            }
        }
    }
    
    func startGameLoop() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
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
        
        var shouldReverse = false
        for i in 0..<enemies.count where !enemies[i].isDying {
            enemies[i].position.x += direction * enemies[i].velocity
            
            if enemies[i].position.x <= 15 || enemies[i].position.x >= screenBounds.width - 15 {
                shouldReverse = true
            }
        }
        
        if shouldReverse {
            direction *= -1
            for i in 0..<enemies.count where !enemies[i].isDying {
                enemies[i].position.y += 5
            }
        }
        
        // Enemy shooting
        enemyShootCounter += 1
        if enemyShootCounter >= 30 && !enemies.isEmpty {
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
        
        checkCollisions()
        checkPlayerHit()
        
        // Check if enemies reached very bottom (give more space)
        if enemies.contains(where: { $0.position.y > screenBounds.height - 20 }) {
            gameOver()
        }
        
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
                    // Yoke shooter splits poo
                    else if bullet.weaponType == .yokeShooter {
                        if enemy.size > 10 {
                            enemiesToUpdate.append((index: index, action: .split))
                        } else {
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
        
        // Process enemy updates from highest index to lowest
        for update in enemiesToUpdate.sorted(by: { $0.index > $1.index }) {
            switch update.action {
            case .die:
                enemies[update.index].isDying = true
            case .split:
                let enemy = enemies[update.index]
                let newSize = enemy.size * 0.6
                enemies.append(PooEnemy(position: CGPoint(x: enemy.position.x - 8, y: enemy.position.y), size: newSize, velocity: enemy.velocity * 1.2))
                enemies.append(PooEnemy(position: CGPoint(x: enemy.position.x + 8, y: enemy.position.y), size: newSize, velocity: enemy.velocity * 1.2))
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
            let distance = hypot(bullet.position.x - playerPosition, bullet.position.y - (screenBounds.height - 35))
            if distance < 20 {
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
        bullets.append(Bullet(position: CGPoint(x: playerPosition, y: screenBounds.height - 40), weaponType: selectedWeapon, isEnemyBullet: false))
    }
    
    func enemyShoot(from position: CGPoint) {
        bullets.append(Bullet(position: position, weaponType: .machineGun, isEnemyBullet: true))
    }
    
    func movePlayer(to position: CGFloat) {
        playerPosition = max(15, min(screenBounds.width - 15, position))
    }
    
    func gameOver() {
        gamePhase = .gameOver
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
                Color.black
                    .ignoresSafeArea()
                
                if gameState.gamePhase == .welcome {
                    VStack(spacing: 15) {
                        Text("🚀 POO SPACE\nBATTLE 💩")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
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
                    VStack(spacing: 15) {
                        Text("GAME OVER")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                        
                        Text("SCORE: \(gameState.score)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        
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
                            Text("\(gameState.score)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            ForEach(0..<gameState.lives, id: \.self) { _ in
                                Text("❤️")
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 5)
                        
                        ZStack {
                            ForEach(gameState.enemies) { enemy in
                                WatchPixelatedPoo(size: enemy.size, deathProgress: enemy.isDying ? enemy.deathAnimationProgress : 0)
                                    .position(enemy.position)
                                    .opacity(enemy.isDying ? 1.0 - enemy.deathAnimationProgress : 1.0)
                            }
                            
                            ForEach(gameState.bullets) { bullet in
                                if bullet.isEnemyBullet {
                                    Capsule()
                                        .fill(Color.red)
                                        .frame(width: 2, height: 8)
                                        .position(bullet.position)
                                } else {
                                    Capsule()
                                        .fill(bullet.weaponType == .machineGun ? Color.yellow : Color.orange)
                                        .frame(width: 2, height: 8)
                                        .position(bullet.position)
                                }
                            }
                            
                            // Player ship with visible gun
                            ZStack {
                                // The ship
                                Text("🚀")
                                    .font(.system(size: 24))
                                
                                // The gun barrel on top
                                if gameState.selectedWeapon == .machineGun {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 2, height: 12)
                                        .offset(y: -15)
                                    
                                    Circle()
                                        .fill(Color.darkGray)
                                        .frame(width: 4, height: 4)
                                        .offset(y: -21)
                                } else {
                                    // Yoke shooter (wider barrel)
                                    Capsule()
                                        .fill(Color.orange)
                                        .frame(width: 4, height: 12)
                                        .offset(y: -15)
                                    
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 5, height: 5)
                                        .offset(y: -21)
                                }
                            }
                            .position(x: gameState.playerPosition, y: geometry.size.height - 35)
                        }
                        
                        Button(action: { gameState.shoot() }) {
                            Text("FIRE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 5)
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
                            gameState.movePlayer(to: value.location.x)
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Pixelated Poo View for Watch (8-bit style)
struct WatchPixelatedPoo: View {
    let size: CGFloat
    let deathProgress: Double
    
    var body: some View {
        let pixelSize = size / 8
        
        Canvas { context, canvasSize in
            let darkBrown = Color(red: 0.4, green: 0.2, blue: 0.1)
            let mediumBrown = Color(red: 0.55, green: 0.27, blue: 0.07)
            let lightBrown = Color(red: 0.65, green: 0.35, blue: 0.15)
            
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
                        
                        // Death animation
                        if deathProgress > 0 {
                            color = color.opacity(1.0 - deathProgress)
                        }
                        
                        let offsetX = deathProgress > 0 ? CGFloat.random(in: -deathProgress * 2...deathProgress * 2) : 0
                        let offsetY = deathProgress > 0 ? CGFloat.random(in: -deathProgress * 2...deathProgress * 2) : 0
                        
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
