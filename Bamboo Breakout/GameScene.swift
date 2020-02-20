//
//  GameScene.swift
//  Bamboo Breakout
/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */ 

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let PaddleCategoryName = "paddle"
let BlockCategoryName = "block"
let GameMessageName = "gameMessage"


class GameScene: SKScene {
  
  override func didMove(to view: SKView) {
    super.didMove(to: view)
    
    
    let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
    borderBody.friction = 0
    self.physicsBody = borderBody
    
    let bottomBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: self.frame.minY), to: CGPoint(x: self.frame.maxX, y: self.frame.minY))
    bottomBody.friction = 0
    let bottomNode = SKNode()
    bottomNode.physicsBody = bottomBody
    addChild(bottomNode)
    
    physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    
    let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
    
    let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
    
    bottomNode.physicsBody?.categoryBitMask = BottomCategory
    ball.physicsBody?.categoryBitMask = BallCategory
    paddle.physicsBody?.categoryBitMask = PaddleCategory
    borderBody.categoryBitMask = BorderCategory
    
    ball.physicsBody?.contactTestBitMask = BottomCategory | BlockCategory | BorderCategory | PaddleCategory
    physicsWorld.contactDelegate = self
    
    addBlocks(count: 8, stacked: true)
    
    let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
    gameMessage.name = GameMessageName
    gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
    gameMessage.zPosition = 4
    gameMessage.setScale(0.0)
    addChild(gameMessage)
        
    gameState.enter(WaitingForTap.self)
    
    let trailNode = SKNode()
    trailNode.zPosition = 1
    addChild(trailNode)
    guard let trail = SKEmitterNode(fileNamed: "SnowTrail") else {return}
    trail.targetNode = trailNode
    ball.addChild(trail)
    
  }
    
    //MARK: Properties
    
    var isFingerOnPaddle: Bool = false
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
    WaitingForTap(scene: self),
    Playing(scene: self),
    GameOver(scene: self)])
    
    
    var gameWon : Bool = false {
      didSet {
        run(gameWon ? gameWonSound : gameOverSound)
        let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
        let textureName = gameWon ? "YouWon" : "GameOver"
        let texture = SKTexture(imageNamed: textureName)
        let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
          SKAction.scale(to: 1.0, duration: 0.25)])
        gameOver.run(actionSequence)
      }
    }
    
    let blipSound = SKAction.playSoundFileNamed("pongblip", waitForCompletion: false)
    let blipPaddleSound = SKAction.playSoundFileNamed("paddleBlip", waitForCompletion: false)
    let bambooBreakSound = SKAction.playSoundFileNamed("BambooBreak", waitForCompletion: false)
    let gameWonSound = SKAction.playSoundFileNamed("game-won", waitForCompletion: false)
    let gameOverSound = SKAction.playSoundFileNamed("game-over", waitForCompletion: false)
    
    
    
    let BallCategory: UInt32 = 0x1 << 0
    let BottomCategory: UInt32 = 0x1 << 1
    let BlockCategory: UInt32 = 0x1 << 2
    let PaddleCategory: UInt32 = 0x1 << 3
    let BorderCategory: UInt32 = 0x1 << 4
  
    
    //MARK: Helper Methods
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
      let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
      return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        
        var numberOfBricks = 0
          self.enumerateChildNodes(withName: BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
          }
        return numberOfBricks == 0
    }
    
    //MARK: Touch Handling Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
            case is WaitingForTap:
              gameState.enter(Playing.self)
              isFingerOnPaddle = true
                
            case is Playing:
              let touch = touches.first
              let touchLocation = touch!.location(in: self)
                
              if let body = physicsWorld.body(at: touchLocation) {
                if body.node!.name == PaddleCategoryName {
                  isFingerOnPaddle = true
                }
              }
            
            case is GameOver:
                let newScene = GameScene(fileNamed:"GameScene")
                newScene!.scaleMode = .aspectFit
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                self.view?.presentScene(newScene!, transition: reveal)
            
            default:
              break
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if isFingerOnPaddle {
            guard let touch = touches.first else {return}
            let touchLocation = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            
            let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
            
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            paddleX = max(paddleX, paddle.size.width/2)
            paddleX = min(paddleX, size.width - paddle.size.width/2)
            
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
    //MARK: Block methods
    func addBlocks(count: Int, stacked:Bool = false) {
        
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlocksWidth = blockWidth * CGFloat(count)
        
        let xOffset = (frame.width - totalBlocksWidth) / 2
        
        for i in 0..<count {
            createBlock(position: i, xOffset: xOffset, blockWidth: blockWidth)
            if stacked {
                createBlock(position: i, xOffset: xOffset, blockWidth: blockWidth, adjustment: 0.1)
            }
        }
        
    }
    
    private func createBlock(position i: Int, xOffset: CGFloat, blockWidth: CGFloat, adjustment: CGFloat = 0.0) {
        let block = SKSpriteNode(imageNamed: "block.png")
        block.position = CGPoint(x: xOffset + ((CGFloat(i) + 0.5) * blockWidth), y: frame.height * (0.8 + adjustment))
        
        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody?.allowsRotation = false
        block.physicsBody?.friction = 0.0
        block.physicsBody?.affectedByGravity = false
        block.physicsBody?.isDynamic = false
        block.name = BlockCategoryName
        block.physicsBody?.categoryBitMask = BlockCategory
        block.zPosition = 2
        addChild(block)

    }
    
    func breakBlock(node: SKNode) {
        run(bambooBreakSound)
        guard let particles = SKEmitterNode(fileNamed: "BrokenPlatform") else {return}
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()]))
        node.removeFromParent()
    }
    
}

//MARK: Physics Contact Delegate extension
extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameState.currentState is Playing {
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            
            if firstBody.categoryBitMask == BallCategory &&
                secondBody.categoryBitMask == BorderCategory {
              run(blipSound)
            }
            
            if firstBody.categoryBitMask == BallCategory &&
                secondBody.categoryBitMask == PaddleCategory {
              run(blipPaddleSound)
            }
            
            
            
            if firstBody.categoryBitMask == BallCategory &&
                secondBody.categoryBitMask == BottomCategory {
                gameState.enter(GameOver.self)
                gameWon = false
            }
            
            if firstBody.categoryBitMask == BallCategory &&
                secondBody.categoryBitMask == BlockCategory {
                breakBlock(node: secondBody.node!)
                if isGameWon() {
                  gameState.enter(GameOver.self)
                  gameWon = true
                }
            }
            
            
        }
    }
    
    
}
