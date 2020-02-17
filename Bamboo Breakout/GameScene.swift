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
    ball.physicsBody?.applyImpulse(CGVector(dx: 2.0, dy: -2.0))
    
    let paddle = childNode(withName: PaddleCategoryName) as! SKSpriteNode
    
    bottomNode.physicsBody?.categoryBitMask = BottomCategory
    ball.physicsBody?.categoryBitMask = BallCategory
    paddle.physicsBody?.categoryBitMask = PaddleCategory
    borderBody.categoryBitMask = BorderCategory
    
    ball.physicsBody?.contactTestBitMask = BottomCategory | BlockCategory
    physicsWorld.contactDelegate = self
    
    addBlocks(count: 8)
  }
    
    //MARK: Properties
    
    var isFingerOnPaddle: Bool = false
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
    WaitingForTap(scene: self),
    Playing(scene: self),
    GameOver(scene: self)])
    
    let BallCategory: UInt32 = 0x1 << 0
    let BottomCategory: UInt32 = 0x1 << 1
    let BlockCategory: UInt32 = 0x1 << 2
    let PaddleCategory: UInt32 = 0x1 << 3
    let BorderCategory: UInt32 = 0x1 << 4
  
    
    //MARK: Touch Handling Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let touch = touches.first
        guard let touchLocation = touch?.location(in: self) else {return}
        
        if let body = physicsWorld.body(at: touchLocation) {
            if body.node?.name == PaddleCategoryName {
                print("Finger is present")
                isFingerOnPaddle = true
            }
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
    
    //MARK: Block methods
    func addBlocks(count: Int) {
        
        let blockWidth = SKSpriteNode(imageNamed: "block").size.width
        let totalBlocksWidth = blockWidth * CGFloat(count)
        
        let xOffset = (frame.width - totalBlocksWidth) / 2
        
        for i in 0..<count {
            let block = SKSpriteNode(imageNamed: "block.png")
            block.position = CGPoint(x: xOffset + ((CGFloat(i) + 0.5) * blockWidth), y: frame.height * 0.8)
            
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
        
    }
    
    func breakBlock(node: SKNode) {
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
            secondBody.categoryBitMask == BottomCategory {
            print("Hit Bottom")
            breakBlock(node: secondBody.node!)
        }
        
        
    }
    
    
}
