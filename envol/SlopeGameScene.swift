import SwiftUI
import SceneKit
import CoreMotion

// Power-up enum for game logic
enum PowerUp: String, CaseIterable {
    case none = "None"
    case shield = "Shield"
    case slowMotion = "Slow Motion"
    case doublePoints = "Double Points"
    
    var cost: Int {
        switch self {
        case .none: return 1
        case .shield: return 3
        case .slowMotion: return 2
        case .doublePoints: return 4
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .shield: return "shield.fill"
        case .slowMotion: return "tortoise.fill"
        case .doublePoints: return "star.fill"
        }
    }
}

// File-scope helpers for neon grid textures
func neonGridTexture(width: Int, height: Int, color: UIColor) -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: width, height: height))
    let ctx = UIGraphicsGetCurrentContext()!
    ctx.setFillColor(UIColor.black.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(4)
    for i in stride(from: 0, to: width, by: 32) {
        ctx.move(to: CGPoint(x: i, y: 0))
        ctx.addLine(to: CGPoint(x: i, y: height))
    }
    for j in stride(from: 0, to: height, by: 32) {
        ctx.move(to: CGPoint(x: 0, y: j))
        ctx.addLine(to: CGPoint(x: width, y: j))
    }
    ctx.strokePath()
    let img = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return img
}

func gridSphereTexture(size: Int, color: UIColor) -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: size, height: size))
    let ctx = UIGraphicsGetCurrentContext()!
    ctx.setFillColor(UIColor.black.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(4)
    for i in stride(from: 0, to: size, by: size/8) {
        ctx.move(to: CGPoint(x: i, y: 0))
        ctx.addLine(to: CGPoint(x: i, y: size))
    }
    for j in stride(from: 0, to: size, by: size/8) {
        ctx.move(to: CGPoint(x: 0, y: j))
        ctx.addLine(to: CGPoint(x: size, y: j))
    }
    ctx.strokePath()
    let img = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return img
}

// Helper: Generate a simple starry sky texture
func starrySkyTexture(size: Int = 1024) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 1)
    let ctx = UIGraphicsGetCurrentContext()!
    ctx.setFillColor(UIColor.black.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    for _ in 0..<400 {
        let x = CGFloat.random(in: 0..<CGFloat(size))
        let y = CGFloat.random(in: 0..<CGFloat(size))
        let r = CGFloat.random(in: 0.5...1.5)
        ctx.setFillColor(UIColor(white: 1, alpha: CGFloat.random(in: 0.5...1)).cgColor)
        ctx.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
    }
    let img = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return img
}

class SlopeGameCoordinator: NSObject, ObservableObject {
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var showEndScreen: Bool = false
    @Published var showSpeedUp: Bool = false
    @Published var isPaused: Bool = false
    var sceneCoordinator: SlopeGameSceneCoordinator?
    var selectedPowerUp: PowerUp = .none
    private var speedUpTimer: Timer?
    
    func resetGame() {
        sceneCoordinator?.resetGame()
        score = 0
        isGameOver = false
        showEndScreen = false
        showSpeedUp = false
        isPaused = false
    }
    
    func triggerGameOver() {
        print("DEBUG: triggerGameOver called")
        DispatchQueue.main.async {
            self.isGameOver = true
            self.showEndScreen = true
            print("DEBUG: isGameOver = \(self.isGameOver), showEndScreen = \(self.showEndScreen)")
        }
    }
    
    func triggerSpeedUpOverlay() {
        showSpeedUp = true
        speedUpTimer?.invalidate()
        speedUpTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.showSpeedUp = false
        }
    }
    
    func pauseGame() {
        isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
    }
    
    func quitGame() {
        isPaused = false
        isGameOver = true
        showEndScreen = true
    }
}

struct SlopeGameSceneView: UIViewRepresentable {
    @ObservedObject var coordinator: SlopeGameCoordinator
    let motionManager = CMMotionManager()

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = makeScene()
        scnView.scene = scene
        scnView.backgroundColor = UIColor.black
        scnView.allowsCameraControl = false
        scnView.isPlaying = true
        scnView.delegate = context.coordinator
        context.coordinator.setupMotion(motionManager: motionManager)
        context.coordinator.setScene(scene)
        coordinator.sceneCoordinator = context.coordinator
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> SlopeGameSceneCoordinator {
        SlopeGameSceneCoordinator(coordinator: coordinator)
    }

    func makeScene() -> SCNScene {
        let scene = SCNScene()
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 2, -12)
        cameraNode.name = "camera"
        scene.rootNode.addChildNode(cameraNode)
        
        // Add glowing grid sphere (player)
        let ball = SCNSphere(radius: 0.4)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = gridSphereTexture(size: 256, color: UIColor.blue)
        ballMaterial.emission.contents = gridSphereTexture(size: 256, color: UIColor.blue)
        ballMaterial.lightingModel = .physicallyBased
        ball.materials = [ballMaterial]
        let ballNode = SCNNode(geometry: ball)
        ballNode.position = SCNVector3(0, 0.4, 0)
        ballNode.name = "ball"
        
        // Add power-up visual effects container
        let powerUpContainer = SCNNode()
        powerUpContainer.name = "powerUpContainer"
        ballNode.addChildNode(powerUpContainer)
        
        // Add glow trail
        let trail = SCNCylinder(radius: 0.18, height: 2.5)
        let trailMaterial = SCNMaterial()
        trailMaterial.diffuse.contents = UIColor.blue.withAlphaComponent(0.18)
        trailMaterial.emission.contents = UIColor.blue.withAlphaComponent(0.25)
        trailMaterial.lightingModel = .constant
        trail.materials = [trailMaterial]
        let trailNode = SCNNode(geometry: trail)
        trailNode.position = SCNVector3(0, 0.4, -1.2)
        trailNode.eulerAngles.x = .pi/2
        trailNode.name = "trail"
        ballNode.addChildNode(trailNode)
        scene.rootNode.addChildNode(ballNode)
        
        // Add lights
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.white
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
        
        return scene
    }
}

class SlopeGameSceneCoordinator: NSObject, SCNSceneRendererDelegate {
    let coordinator: SlopeGameCoordinator
    var ballNode: SCNNode?
    var cameraNode: SCNNode?
    var zPos: Float = 0
    var xPos: Float = 0
    var yPos: Float = 0.4
    var speed: Float = 0.18
    var motionManager: CMMotionManager?
    var scene: SCNScene?
    
    // Dynamic track and obstacles
    var trackSegments: [SCNNode] = []
    var obstacles: [SCNNode] = []
    let segmentLength: Float = 10
    let visibleSegments: Int = 25
    let obstacleSpacing: Float = 10
    let obstacleChance: Float = 0.5
    var isFalling: Bool = false
    var fallVelocity: Float = 0
    var fallTimer: Float = 0
    var ballRotation: Float = 0
    var trackWidth: Float = 4.0
    var buildingNodes: [SCNNode] = []
    let buildingRows: Int = 30
    let buildingsPerRow: Int = 8
    let buildingSpacing: Float = 4.5
    let buildingMinHeight: Float = 4
    let buildingMaxHeight: Float = 18
    let buildingDistance: Float = 60
    var baseGameSpeed: Float = 0.18
    var gameSpeed: Float = 0.18
    var lastSpeedUpScore: Int = 0
    
    // Power-up state
    var shieldHits: Int = 0
    var maxShieldHits: Int = 3
    var isShieldActive: Bool = false
    var isSlowMotionActive: Bool = false
    var isDoublePointsActive: Bool = false
    var speedUpInterval: Int = 50 // Default 50, changes to 100 for slow motion

    init(coordinator: SlopeGameCoordinator) {
        self.coordinator = coordinator
    }

    func setScene(_ scene: SCNScene) {
        self.scene = scene
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)
        cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)
        zPos = 0
        xPos = 0
        yPos = 0.4
        isFalling = false
        fallVelocity = 0
        fallTimer = 0
        ballRotation = 0
        baseGameSpeed = 0.18
        gameSpeed = 0.18
        lastSpeedUpScore = 0
        for node in trackSegments + obstacles + buildingNodes { node.removeFromParentNode() }
        trackSegments.removeAll()
        obstacles.removeAll()
        buildingNodes.removeAll()
        
        // Spawn initial track segments
        for i in 0..<visibleSegments {
            spawnTrackSegment(at: Float(i) * segmentLength)
            if i > 1 && Float.random(in: 0...1) < obstacleChance {
                spawnObstacle(at: Float(i) * segmentLength + segmentLength/2)
            }
        }
        
        // Add skybox
        let sky = starrySkyTexture(size: 1024)
        scene.background.contents = [sky, sky, sky, sky, sky, sky]
        
        // Add initial buildings
        for i in 0..<buildingRows {
            spawnBuildings(at: Float(i) * segmentLength)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let scene = renderer.scene else { return }
        if ballNode == nil {
            ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)
        }
        if cameraNode == nil {
            cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)
        }
        guard let ballNode = ballNode, let cameraNode = cameraNode else { return }
        if coordinator.isGameOver { return }
        if coordinator.isPaused { return }
        
        // Check if power-up needs to be initialized (first frame)
        if !isShieldActive && !isSlowMotionActive && !isDoublePointsActive && coordinator.selectedPowerUp != .none {
            print("DEBUG: Auto-initializing power-up in renderer: \(coordinator.selectedPowerUp.rawValue)")
            initializePowerUps()
        }
        
        // Move ball forward
        zPos += gameSpeed
        
        // Invert tilt direction
        if let roll = motionManager?.deviceMotion?.attitude.roll {
            xPos = -Float(roll) * 3.0
        }
        
        // Check if ball is on track or falling off edge
        let trackLeft = -trackWidth/2
        let trackRight = trackWidth/2
        var onTrack = false
        var currentTrackSegment: SCNNode?
        for node in trackSegments {
            if abs(node.position.z - zPos) < segmentLength/2 {
                onTrack = true
                currentTrackSegment = node
                break
            }
        }
        
        // Check if ball is within track bounds (can fall off edges)
        if onTrack {
            if xPos < trackLeft || xPos > trackRight {
                onTrack = false
            }
        }
        
        // Handle falling
        if !onTrack && !isFalling {
            isFalling = true
            fallVelocity = 0
            fallTimer = 0
        }
        
        // Animate falling with rotation
        if isFalling {
            fallVelocity += 0.025
            yPos -= fallVelocity
            fallTimer += 1
            ballRotation += gameSpeed * 2.0
            if yPos < -5 {
                print("DEBUG: Ball fell off, triggering game over")
                coordinator.triggerGameOver()
                return
            }
        } else {
            yPos = 0.4
            ballRotation += gameSpeed * 1.5
        }
        
        // Apply position and rotation to ball
        ballNode.position = SCNVector3(xPos, yPos, zPos)
        ballNode.eulerAngles.z = ballRotation
        
        // Camera follows behind and looks at the ball
        let camOffset: Float = -15
        cameraNode.position = SCNVector3(xPos, 3, zPos + camOffset)
        cameraNode.look(at: SCNVector3(xPos, yPos, zPos))
        
        // Dynamic track segment management
        if let last = trackSegments.last, zPos + segmentLength * 3 > last.position.z {
            spawnTrackSegment(at: last.position.z + segmentLength)
            if Float.random(in: 0...1) < obstacleChance {
                spawnObstacle(at: last.position.z + segmentLength/2)
            }
        }
        
        // Remove segments/obstacles far behind
        trackSegments.removeAll { node in
            if zPos - node.position.z > segmentLength * 3 {
                node.removeFromParentNode()
                return true
            }
            return false
        }
        
        // Only despawn obstacles after they are fully off screen (behind camera)
        let cameraZ = zPos + camOffset
        obstacles.removeAll { node in
            if node.position.z < cameraZ - 2 {
                node.removeFromParentNode()
                return true
            }
            return false
        }
        
        // Manage buildings
        if let last = buildingNodes.last, zPos + segmentLength * 5 > last.position.z {
            spawnBuildings(at: last.position.z + segmentLength)
        }
        buildingNodes.removeAll { node in
            if node.position.z < cameraZ - 10 {
                node.removeFromParentNode()
                return true
            }
            return false
        }
        
        // Check for collisions with obstacles (only when not falling)
        if !isFalling {
            for node in obstacles {
                let dx = node.position.x - ballNode.position.x
                let dz = node.position.z - ballNode.position.z
                if abs(dx) < 0.7 && abs(dz) < 0.7 {
                    print("DEBUG: Collision detected! Shield active: \(isShieldActive), Shield hits: \(shieldHits)/\(maxShieldHits)")
                    if isShieldActive {
                        // Shield power-up: tank hits
                        shieldHits += 1
                        print("DEBUG: Shield hit! Hits taken: \(shieldHits)/\(maxShieldHits)")
                        
                        // Update shield visual to show damage
                        updateShieldVisual()
                        
                        // Remove the obstacle that was hit
                        node.removeFromParentNode()
                        obstacles.removeAll { $0 == node }
                        
                        if shieldHits >= maxShieldHits {
                            print("DEBUG: Shield broken, triggering game over")
                            coordinator.triggerGameOver()
                            return
                        }
                    } else {
                        print("DEBUG: Ball hit obstacle, triggering game over")
                        coordinator.triggerGameOver()
                        return
                    }
                }
            }
        }
        
        // Update score with power-up multiplier
        let baseScore = Int(zPos)
        if isDoublePointsActive {
            coordinator.score = baseScore * 2
        } else {
            coordinator.score = baseScore
        }
        
        // Speed up based on power-up interval (use base score for speed calculation)
        if baseScore >= lastSpeedUpScore + speedUpInterval {
            lastSpeedUpScore = (baseScore / speedUpInterval) * speedUpInterval
            gameSpeed += 0.04
            coordinator.triggerSpeedUpOverlay()
        }
    }

    func setupMotion(motionManager: CMMotionManager) {
        self.motionManager = motionManager
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
    }

    func resetGame() {
        zPos = 0
        xPos = 0
        yPos = 0.4
        isFalling = false
        fallVelocity = 0
        fallTimer = 0
        ballRotation = 0
        if let ballNode = ballNode {
            ballNode.position = SCNVector3(0, 0.4, 0)
            ballNode.eulerAngles.z = 0
        }
        if let cameraNode = cameraNode {
            cameraNode.position = SCNVector3(0, 3, -15)
            cameraNode.look(at: SCNVector3(0, 0.4, 0))
        }
        for node in trackSegments + obstacles + buildingNodes { node.removeFromParentNode() }
        trackSegments.removeAll()
        obstacles.removeAll()
        buildingNodes.removeAll()
        if let scene = scene {
            for i in 0..<visibleSegments {
                spawnTrackSegment(at: Float(i) * segmentLength)
                if i > 1 && Float.random(in: 0...1) < obstacleChance {
                    spawnObstacle(at: Float(i) * segmentLength + segmentLength/2)
                }
            }
            for i in 0..<buildingRows {
                spawnBuildings(at: Float(i) * segmentLength)
            }
        }
        
        // Initialize power-ups AFTER scene is set up
        DispatchQueue.main.async {
            self.initializePowerUps()
        }
    }
    
    func initializePowerUps() {
        // Reset power-up state
        shieldHits = 0
        isShieldActive = false
        isSlowMotionActive = false
        isDoublePointsActive = false
        speedUpInterval = 50
        
        // Clear existing power-up visuals
        clearPowerUpVisuals()
        
        // Apply selected power-up
        print("DEBUG: Initializing power-up: \(coordinator.selectedPowerUp.rawValue)")
        switch coordinator.selectedPowerUp {
        case .shield:
            isShieldActive = true
            addShieldVisual()
            print("DEBUG: Shield power-up activated - isShieldActive: \(isShieldActive)")
        case .slowMotion:
            isSlowMotionActive = true
            speedUpInterval = 100
            addSlowMotionVisual()
            print("DEBUG: Slow Motion power-up activated - speed increases every 100 points")
        case .doublePoints:
            isDoublePointsActive = true
            addDoublePointsVisual()
            print("DEBUG: Double Points power-up activated - double points, normal speed progression")
        case .none:
            print("DEBUG: No power-up selected")
        }
    }
    
    func activatePowerUp(_ powerUp: PowerUp) {
        print("DEBUG: Manually activating power-up: \(powerUp.rawValue)")
        coordinator.selectedPowerUp = powerUp
        initializePowerUps()
    }
    
    func clearPowerUpVisuals() {
        guard let ballNode = ballNode,
              let powerUpContainer = ballNode.childNode(withName: "powerUpContainer", recursively: true) else { return }
        
        // Remove all existing power-up visual nodes
        powerUpContainer.childNodes.forEach { $0.removeFromParentNode() }
    }
    
    func addShieldVisual() {
        guard let ballNode = ballNode,
              let powerUpContainer = ballNode.childNode(withName: "powerUpContainer", recursively: true) else { 
            print("DEBUG: Failed to create shield visual - missing ballNode or powerUpContainer")
            return 
        }
        
        print("DEBUG: Creating shield visual")
        
        // Create shield bubble effect
        let shield = SCNSphere(radius: 0.6)
        let shieldMaterial = SCNMaterial()
        shieldMaterial.diffuse.contents = UIColor.cyan.withAlphaComponent(0.3)
        shieldMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.4)
        shieldMaterial.lightingModel = .constant
        shieldMaterial.transparency = 0.6
        shield.materials = [shieldMaterial]
        
        let shieldNode = SCNNode(geometry: shield)
        shieldNode.name = "shieldVisual"
        
        // Add pulsing animation
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 0.8),
            SCNAction.scale(to: 1.0, duration: 0.8)
        ])
        shieldNode.runAction(SCNAction.repeatForever(pulseAction))
        
        powerUpContainer.addChildNode(shieldNode)
    }
    
    func addSlowMotionVisual() {
        guard let ballNode = ballNode,
              let powerUpContainer = ballNode.childNode(withName: "powerUpContainer", recursively: true) else { return }
        
        // Create slow motion time distortion effect
        let timeRing = SCNTorus(ringRadius: 0.8, pipeRadius: 0.05)
        let timeMaterial = SCNMaterial()
        timeMaterial.diffuse.contents = UIColor.orange.withAlphaComponent(0.8)
        timeMaterial.emission.contents = UIColor.orange.withAlphaComponent(0.9)
        timeMaterial.lightingModel = .constant
        timeRing.materials = [timeMaterial]
        
        let timeNode = SCNNode(geometry: timeRing)
        timeNode.name = "slowMotionVisual"
        timeNode.eulerAngles.x = .pi/2
        
        // Add rotation animation
        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 2.0)
        timeNode.runAction(SCNAction.repeatForever(rotateAction))
        
        powerUpContainer.addChildNode(timeNode)
    }
    
    func addDoublePointsVisual() {
        guard let ballNode = ballNode,
              let powerUpContainer = ballNode.childNode(withName: "powerUpContainer", recursively: true) else { return }
        
        // Create star effect for double points
        let starRing = SCNTorus(ringRadius: 0.7, pipeRadius: 0.03)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor.yellow.withAlphaComponent(0.8)
        starMaterial.emission.contents = UIColor.yellow.withAlphaComponent(0.9)
        starMaterial.lightingModel = .constant
        starRing.materials = [starMaterial]
        
        let starNode = SCNNode(geometry: starRing)
        starNode.name = "doublePointsVisual"
        starNode.eulerAngles.x = .pi/2
        
        // Add pulsing and rotation animation
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 0.6),
            SCNAction.scale(to: 1.0, duration: 0.6)
        ])
        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: -.pi * 2, duration: 1.5)
        
        starNode.runAction(SCNAction.repeatForever(pulseAction))
        starNode.runAction(SCNAction.repeatForever(rotateAction))
        
        powerUpContainer.addChildNode(starNode)
    }
    
    func updateShieldVisual() {
        guard let ballNode = ballNode,
              let powerUpContainer = ballNode.childNode(withName: "powerUpContainer", recursively: true),
              let shieldNode = powerUpContainer.childNode(withName: "shieldVisual", recursively: true) else { 
            print("DEBUG: Failed to update shield visual - missing nodes")
            return 
        }
        
        print("DEBUG: Updating shield visual for hit \(shieldHits)")
        
        // Change shield color based on remaining hits
        let remainingHits = maxShieldHits - shieldHits
        let shieldMaterial = shieldNode.geometry?.materials.first
        
        switch remainingHits {
        case 3:
            shieldMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.3)
            shieldMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.4)
        case 2:
            shieldMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.3)
            shieldMaterial?.emission.contents = UIColor.yellow.withAlphaComponent(0.4)
        case 1:
            shieldMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.3)
            shieldMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.4)
        default:
            break
        }
        
        // Add a flash effect when hit
        let flashAction = SCNAction.sequence([
            SCNAction.scale(to: 1.3, duration: 0.1),
            SCNAction.scale(to: 1.0, duration: 0.1)
        ])
        shieldNode.runAction(flashAction)
    }

    // Dynamic spawning
    func spawnTrackSegment(at z: Float) {
        guard let scene = scene else { return }
        let track = SCNBox(width: CGFloat(trackWidth), height: 0.1, length: CGFloat(segmentLength), chamferRadius: 0)
        let trackMaterial = SCNMaterial()
        trackMaterial.diffuse.contents = neonGridTexture(width: 256, height: 256, color: UIColor.green)
        trackMaterial.emission.contents = neonGridTexture(width: 256, height: 256, color: UIColor.green)
        trackMaterial.lightingModel = .constant
        track.materials = [trackMaterial]
        let trackNode = SCNNode(geometry: track)
        trackNode.position = SCNVector3(0, 0, z)
        trackNode.name = "trackSegment"
        scene.rootNode.addChildNode(trackNode)
        trackSegments.append(trackNode)
    }
    
    func spawnObstacle(at z: Float) {
        guard let scene = scene else { return }
        let type = Int.random(in: 0...3)
        switch type {
        case 0:
            // Single cube
            spawnCube(x: Float.random(in: -1.5...1.5), z: z)
        case 1:
            // Double cubes (gap in middle)
            spawnCube(x: -1.0, z: z)
            spawnCube(x: 1.0, z: z)
        case 2:
            // Triple cubes (wall with one gap)
            let gap = Int.random(in: 0...2)
            for i in 0...2 {
                if i != gap {
                    spawnCube(x: -1.5 + Float(i) * 1.5, z: z)
                }
            }
        case 3:
            // Cluster (two cubes close together)
            let base = Float.random(in: -1.0...0.5)
            spawnCube(x: base, z: z)
            spawnCube(x: base + 0.7, z: z)
        default:
            spawnCube(x: Float.random(in: -1.5...1.5), z: z)
        }
    }
    
    func spawnCube(x: Float, z: Float) {
        guard let scene = scene else { return }
        let cube = SCNBox(width: 0.8, height: 0.8, length: 0.8, chamferRadius: 0.1)
        let cubeMaterial = SCNMaterial()
        cubeMaterial.diffuse.contents = neonGridTexture(width: 128, height: 128, color: UIColor.red)
        cubeMaterial.emission.contents = neonGridTexture(width: 128, height: 128, color: UIColor.red)
        cubeMaterial.lightingModel = .constant
        cube.materials = [cubeMaterial]
        let cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(x, 0.4, z)
        cubeNode.name = "obstacle"
        scene.rootNode.addChildNode(cubeNode)
        obstacles.append(cubeNode)
    }

    // Neon city buildings
    func spawnBuildings(at z: Float) {
        guard let scene = scene else { return }
        let gridMat = SCNMaterial()
        gridMat.diffuse.contents = neonGridTexture(width: 256, height: 1024, color: UIColor.green)
        gridMat.emission.contents = neonGridTexture(width: 256, height: 1024, color: UIColor.green)
        gridMat.lightingModel = .constant
        for side in [-1, 1] {
            for i in 0..<buildingsPerRow {
                let x = Float(side) * (buildingDistance + Float(i) * buildingSpacing)
                let height = Float.random(in: buildingMinHeight...buildingMaxHeight)
                let box = SCNBox(width: 3, height: CGFloat(height), length: 3, chamferRadius: 0.1)
                box.materials = [gridMat]
                let node = SCNNode(geometry: box)
                node.position = SCNVector3(x, height/2, z + Float.random(in: -2...2))
                node.name = "building"
                scene.rootNode.addChildNode(node)
                buildingNodes.append(node)
            }
        }
    }
}
