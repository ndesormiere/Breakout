//
//  GameScene.swift
//  Breakout
//
//  Created by Nicolas Desormiere on 9/6/2016.
//  Copyright (c) 2016 nicolasdesormiere. All rights reserved.
//

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"

let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var isFingerOnPaddle = false
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNodeWithName(GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "YouWon" : "GameOver"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                SKAction.scaleTo(1.0, duration: 0.25)])
            
            gameOver.runAction(actionSequence)
            runAction(gameWon ? gameWonSound : gameOverSound)
        }
    }
    
    let blipSound = SKAction.playSoundFileNamed("pongblip", waitForCompletion: false)
    let blipPaddleSound = SKAction.playSoundFileNamed("paddleBlip", waitForCompletion: false)
    let bambooBreakSound = SKAction.playSoundFileNamed("BambooBreak", waitForCompletion: false)
    let gameWonSound = SKAction.playSoundFileNamed("game-won", waitForCompletion: false)
    let gameOverSound = SKAction.playSoundFileNamed("game-over", waitForCompletion: false)
    
    
    // MARK: - Setup
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        
        let borderBody = SKPhysicsBody(edgeLoopFromRect: self.frame)
        
        borderBody.friction = 0
        
        self.physicsBody = borderBody
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let ball = childNodeWithName(BallCategoryName) as! SKSpriteNode
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFromRect: bottomRect)
        addChild(bottom)
        
        let paddle = childNodeWithName(PaddleCategoryName) as! SKSpriteNode
        
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        borderBody.categoryBitMask = BorderCategory
        
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | BorderCategory | PaddleCategory
        
        
        let numberOfBlocks = 8
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        
        let xOffset = (CGRectGetWidth(frame) - totalBlocksWidth) / 2
        
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: CGRectGetHeight(frame) * 0.8)
            
            block.physicsBody = SKPhysicsBody(rectangleOfSize: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.dynamic = false
            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
        
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        let trailNode = SKNode()
        trailNode.zPosition = 1
        addChild(trailNode)
        let trail = SKEmitterNode(fileNamed: "BallTrail")!
        trail.targetNode = trailNode
        ball.addChild(trail)
        
        
        gameState.enterState(WaitingForTap)
    }
    
    // MARK: Events
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enterState(Playing)
            isFingerOnPaddle = true
            
        case is Playing:
            let touch = touches.first
            let touchLocation = touch!.locationInNode(self)
            
            if let body = physicsWorld.bodyAtPoint(touchLocation) {
                if body.node!.name == PaddleCategoryName {
                    isFingerOnPaddle = true
                }
            }
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .AspectFit
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // 1.
        if isFingerOnPaddle {
            // 2.
            let touch = touches.first
            let touchLocation = touch!.locationInNode(self)
            let previousLocation = touch!.previousLocationInNode(self)
            // 3.
            let paddle = childNodeWithName(PaddleCategoryName) as! SKSpriteNode
            // 4.
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            // 5.
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            // 6.
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isFingerOnPaddle = false
    }
    
    override func update(currentTime: NSTimeInterval) {
        gameState.updateWithDeltaTime(currentTime)
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBeginContact(contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            // 1.
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            // 2.
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            // React to contact with bottom of screen
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
                gameState.enterState(GameOver)
                gameWon = false
            }
            // React to contact with blocks
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(secondBody.node!)
                if isGameWon() {
                    gameState.enterState(GameOver)
                    gameWon = true
                }
            }
            // 1.
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
                runAction(blipSound)
            }
            
            // 2.
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
                runAction(blipPaddleSound)
            }
            
            
            
        }
    }
    
    // MARK: - Helpers
    func breakBlock(node: SKNode) {
        runAction(bambooBreakSound)
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.removeFromParent()]))
        node.removeFromParent()
    }
    
    func randomFloat(from from:CGFloat, to:CGFloat) -> CGFloat {
        let rand:CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodesWithName(BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    
}
