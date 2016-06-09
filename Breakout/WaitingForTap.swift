//
//  WaitingForTap.swift
//  Breakout
//
//  Created by Nicolas Desormiere on 9/6/2016.
//  Copyright © 2016 nicolasdesormiere. All rights reserved.
//

import SpriteKit
import GameplayKit

class WaitingForTap: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnterWithPreviousState(previousState: GKState?) {
        let scale = SKAction.scaleTo(1.0, duration: 0.25)
        scene.childNodeWithName(GameMessageName)!.runAction(scale)
    }
    
    override func willExitWithNextState(nextState: GKState) {
        if nextState is Playing {
            let scale = SKAction.scaleTo(0, duration: 0.4)
            scene.childNodeWithName(GameMessageName)!.runAction(scale)
        }
    }
    
    override func isValidNextState(stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
    
}
