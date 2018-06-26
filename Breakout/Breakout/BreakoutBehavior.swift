//
//  BreakoutBehavior.swift
//  Breakout
//
//  Created by Pavan Kulhalli on 03/04/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class BreakoutBehavior: UIDynamicBehavior,UICollisionBehaviorDelegate {

    private var balls = [BallView]()
    private var collisionHandlers = [String:()->Void]()
    
    private let gravity: UIGravityBehavior = {
        let behavior = UIGravityBehavior()
        behavior.magnitude = 0
        return behavior
    } ()
    
    private lazy var collider: UICollisionBehavior = {
        let collider = UICollisionBehavior()
        collider.collisionMode = .boundaries
        collider.collisionDelegate = self
        collider.translatesReferenceBoundsIntoBoundary = true
        return collider
    }()
    
    private var itemBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.allowsRotation = false
        behavior.elasticity = 0.8
        behavior.resistance = 0
        behavior.friction = 0
        behavior.angularResistance = 0
        return behavior
    }()
    
    override init() {
        super.init()
        addChildBehavior(gravity)
        addChildBehavior(collider)
        addChildBehavior(itemBehavior)
    }
    
    func addItem(_ item: UIDynamicItem) {
        if let ball = item as? BallView {
            balls.append(ball)
        }
        gravity.addItem(item)
        collider.addItem(item)
        itemBehavior.addItem(item)
    }
    
    func removeItem(_ item: UIDynamicItem) {
        if let ball = item as? BallView,
            let index = balls.index(of: ball) {
            balls.remove(at: index)
        }
        gravity.removeItem(item)
        collider.removeItem(item)
        itemBehavior.removeItem(item)
    }
    
    
    // MARK: - collision boundaries & handlers
    func addBoundary(from point1: CGPoint, to point2: CGPoint, named name: String, collisionHandler: (()->Void)?=nil) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collider.addBoundary(withIdentifier: name as NSString, from: point1, to: point2)
        collisionHandlers[name] = collisionHandler
    }
    
    func addBoundary(_ path: UIBezierPath, named name: String, collisionHandler: (()->Void)?=nil) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collider.addBoundary(withIdentifier: name as NSString, for: path)
        collisionHandlers[name] = collisionHandler
    }
    
    func removeBoundary(named name: String) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collisionHandlers[name] = nil
    }
    
    // Called when ball collides with different game objects in the game
    func collisionBehavior(_ behavior: UICollisionBehavior,
                           endedContactFor item: UIDynamicItem,
                           withBoundaryIdentifier identifier: NSCopying?
        ) {
        if let name = identifier as? String {
            if let handler = collisionHandlers[name] {
                handler()
                if name.lowercased().range(of:"brick") != nil {
                    NotificationCenter.default.post(name: Notification.Name("scoreUpdater"), object: nil)
                }

            }
        }
    }
    
    func setGravity(vector: CGVector) {
        gravity.gravityDirection = vector
    }
    
    func setBallBounciness(_ magnitude: CGFloat) {
        itemBehavior.elasticity = magnitude
    }
    
    func setCollidersAction(_ action: @escaping ()->Void) {
        collider.action = action
    }
    
    func clearCollisionBoundariesAndHandlers() {
        collisionHandlers.removeAll()
        collider.removeAllBoundaries()
    }
    
    func launchBall() {
        for ball in balls {
            let pushBehavior = UIPushBehavior(items: [ball], mode: .instantaneous)
            pushBehavior.magnitude = 0.6
            pushBehavior.angle = CGFloat.random(in: 4/3*CGFloat.pi..<5/3*CGFloat.pi)
            pushBehavior.active = true
            pushBehavior.action = { [unowned self] in
                self.removeChildBehavior(pushBehavior)
            }
            addChildBehavior(pushBehavior)
        }
    }
    
    func clearItems() {
        for ball in balls {
            removeItem(ball)
        }
    }
}

extension CGFloat {
    static func random(max: Int) -> CGFloat {
        return CGFloat(arc4random() % UInt32(max))
    }
    
    static func random(in range: Range<CGFloat>) -> CGFloat {
        return CGFloat(arc4random())/CGFloat(UInt32.max) * (range.upperBound-range.lowerBound) + range.lowerBound
    }
}

