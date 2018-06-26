//
//  UserDefaults.swift
//  Breakout
//
//  Created by Pavan Kulhalli on 03/04/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import Foundation

final class UserDefaultsManager {

    static let defaults = UserDefaults.standard
    
    struct keys {
        static let numberOfBalls = "Number Of Balls"
        static let numberOfBricks = "Number Of Bricks"
        static let ballBounciness = "Ball Bounciness"
    }
    
    static var numberOfBricks: Int? {
        get {
            return defaults.value(forKey: keys.numberOfBricks) as? Int
        }
        set {
            defaults.set(newValue, forKey: keys.numberOfBricks)
            defaults.synchronize()
        }
    }
    
    static var numberOfBalls: Int? {
        get {
            return defaults.value(forKey: keys.numberOfBalls) as? Int
        }
        set {
            defaults.set(newValue, forKey: keys.numberOfBalls)
            defaults.synchronize()
        }
    }
    
    static var ballBounciness: Float? {
        get {
            return defaults.value(forKey: keys.ballBounciness) as? Float
        }
        set {
            defaults.set(newValue, forKey: keys.ballBounciness)
            defaults.synchronize()
        }
    }
    
}
