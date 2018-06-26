//
//  GameView.swift
//  Breakout
//
//  Created by Pavan Kulhalli on 03/04/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class GameView: UIView {

    private var bouncingBalls = [(ball: BallView, isAnimated: Bool)]()
    private var bricks = [BricksView?]()
    private var paddle: UIView!
    var ballCount: Int = 1
    struct BoundaryNames {
        static let brick = "Brick"
        static let paddle = "Paddle"
        static let bounds = "Bounds"
        static let left = "Left"
        static let right = "Right"
        static let upper = "Upper"
    }

    struct Constants {
        static let defaultNumberOfBricks: Int = 20
        static let maximumBricks: Int = 40
        static let numberOfBrickColumns: Int = 5
        static let boundsHeightToBrickHeightRatio: CGFloat = 0.03
        static let brickInterspace: CGFloat = 10.0
        static let bricksOffsetFromTop: CGFloat = 50.0
        
        static let brickToPaddleWidthRatio: CGFloat = 1.5
        static let brickToPaddleHeightRatio: CGFloat = 0.5
        static let paddleOffsetFromBottomToHeightRatio: CGFloat = 0.15
        static let boundsHeightToBrickOffsetFromTopRatio: CGFloat = 8
        
        static let brickVanishTime: TimeInterval = 0.5
        
        static let maximumNumberOfBalls: Int = 3
        static let defaultBallBounciness: CGFloat = 1.0
        static let defautlNumberOfBalls: Int = 1
        static let ballPusherMagnitude: CGFloat = 0.6
        static let ballPusherAngleRange: Range = 4/3*CGFloat.pi..<5/3*CGFloat.pi
        static let defaultGravityMagnitude: CGFloat = 0.1
        static let ballSize = CGSize.init(width: 20, height: 20)
    }
    
    //MARK: - initilaizer
    
    func initGameView(frame: CGRect, breakoutBehavior: BreakoutBehavior, ballCount: Int, brickCount: Int, ballBounciness: CGFloat) {
        self.backgroundColor = UIColor.white
        self.numberOfBalls = ballCount
        self.numberOfBricks = brickCount
        self.ballBounciness = ballBounciness
        
        self.set(breakoutBehavior: breakoutBehavior)
        self.setUpNewGameView()
    }
    
    // MARK: - game controlling (settings) variables
    
    private var breakoutBehavior: BreakoutBehavior?
    private var numberOfBalls: Int = 1
    private var numberOfBricks: Int = Constants.defaultNumberOfBricks
    private var ballBounciness: CGFloat = 1.0
    
    
    private func set(breakoutBehavior: BreakoutBehavior) {
        self.breakoutBehavior = breakoutBehavior
        
        breakoutBehavior.setCollidersAction { [weak self] in
            self?.returnBallToPaddleIfNecessary()
        }
        breakoutBehavior.setBallBounciness(ballBounciness)
    }
    
    func set(ballCount: Int, brickCount: Int, bounciness: CGFloat) {
        
        if ballCount != numberOfBalls || brickCount != numberOfBricks {
            numberOfBalls = ballCount
            numberOfBricks = brickCount
            clearViewToRestartGame()
            setUpNewGameView()
        }
        
        ballBounciness = bounciness
        
        if let behavior = breakoutBehavior {
            behavior.setBallBounciness(bounciness)
        }
    }
    
    
    // MARK: - game lifecycle variable
    private var numberOfBricksDown: Int = 0 {
        didSet {
            if numberOfBricksDown == numberOfBricks {
                clearViewToRestartGame()
                wellDoneNewGameAlert()
            }
        }
    }
    
    private func wellDoneNewGameAlert() {
        let alert = UIAlertController(title: "Congratulations!", message: "You used \(ballCount) balls to complete the game", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default)
        { [unowned self] action in
            self.setUpNewGameView()
        })
        
        var rootVC = UIApplication.shared.keyWindow?.rootViewController
        if let tabVC = rootVC as? UITabBarController {
            rootVC = tabVC.selectedViewController
        }
        rootVC?.present(alert, animated: true, completion: nil)
    }
    
    
    
    func setUpNewGameView() {
        if let behavior = breakoutBehavior {
            addScreenBoundary(to: behavior)
            drawPaddleAndAddItsBoundary(to: behavior)
            drawBricksAndAddTheirBoundaries(to: behavior)
            drawBalls()
            ballCount = 1
            NotificationCenter.default.post(name: Notification.Name("newGame"), object: nil)
        }
    }
    
    private func clearViewToRestartGame() {
        breakoutBehavior?.clearCollisionBoundariesAndHandlers()
        deleteBalls()
        deleteBricks()
        deletePaddle()
    }
    
    func redrawGameViewUponRotation() {
        if let behavior = breakoutBehavior {
            behavior.clearCollisionBoundariesAndHandlers()
            withdrawBricksFromGameView()
            deletePaddle()
            
            addScreenBoundary(to: behavior)
            drawPaddleAndAddItsBoundary(to: behavior)
            redrawExistingBricksAndAddTheirBoundaries(to: behavior)
            resizeAndMoveBallsUponRotation()
        }
    }
    
    private func resizeAndMoveBallsUponRotation() {
        for (ball, isAnimated) in bouncingBalls {
            ball.frame.size = ballSize
            bringSubview(toFront: ball)
            if !isAnimated {
                ball.center = newBallCenter
            }
            ball.layoutIfNeeded()
        }
    }
    
    private func addScreenBoundary(to behavior: BreakoutBehavior) {
        let gameRectangle = bounds.insetBy(dx: 10, dy:  10)
        behavior.addBoundary(from: gameRectangle.lowerLeft, to: gameRectangle.upperLeft, named: BoundaryNames.left)
        behavior.addBoundary(from: gameRectangle.upperLeft, to: gameRectangle.upperRight, named: BoundaryNames.upper)
        behavior.addBoundary(from: gameRectangle.lowerRight, to: gameRectangle.upperRight, named: BoundaryNames.right)
    }
    
    private func drawBricksAndAddTheirBoundaries(to behavior: BreakoutBehavior) {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: 10, y: bricksOffsetFromTop)
        
        while numberOfDrawnBricks < numberOfBricks {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = 10
                upperLeftPointOfNextBrick.y += brickSize.height + 10
            }
            
            let brick = BricksView(frame: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize))
            bricks.append(brick)
            
            addSubview(brick)
            
            let brickBoundaryPath = UIBezierPath(rect: brick.frame)
            let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)
            behavior.addBoundary(
                brickBoundaryPath,
                named: brickBoundaryName,
                collisionHandler: { [weak self] in
                    UIView.animate(
                        withDuration: 0.5,
                        delay: 0.0,
                        options: [.curveEaseOut],
                        animations: {
                            //TODO: make some hitBrick Animation
                            behavior.removeBoundary(named: brickBoundaryName)
                            Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { timer in
                                brick.alpha = 0.0
                            }
                    },
                        completion: { finished in
                            if finished {
                                brick.removeFromSuperview()
                                let indexOfInt = brickBoundaryName.index(brickBoundaryName.startIndex, offsetBy: 5)
                                //TODO: extracting int from string is probably a temporary solution.
                                // 5 is number of chars in "Brick12" before int appears. This should be done more thoughtfully.
                                if let index = Int(brickBoundaryName[indexOfInt...]) {
                                    self?.bricks[index] = nil
                                }
                                self?.numberOfBricksDown += 1
                            }
                    }
                    )
                }
            )
            upperLeftPointOfNextBrick.x += brickSize.width + Constants.brickInterspace
            numberOfDrawnBricks += 1
        }
    }
    
    private func redrawExistingBricksAndAddTheirBoundaries(to behavior: BreakoutBehavior) {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: Constants.brickInterspace, y: bricksOffsetFromTop)
        
        for (index, brick) in bricks.enumerated() {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = Constants.brickInterspace
                upperLeftPointOfNextBrick.y += brickSize.height + Constants.brickInterspace
            }
            
            if brick != nil {
                bricks[index] = nil
                let newBrick = BricksView(frame: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize))
                
                bricks[index] = newBrick
                addSubview(newBrick)
                
                let brickBoundaryPath = UIBezierPath(rect: newBrick.frame)
                let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)  // Starts with Brick0
                behavior.addBoundary(
                    brickBoundaryPath,
                    named: brickBoundaryName,
                    collisionHandler: { [weak self] in
                        UIView.animate(
                            withDuration: 5.0,
                            delay: 0.0,
                            options: [.curveEaseOut],
                            animations: {
                                //TODO: make some hitBrick Animation
                                behavior.removeBoundary(named: brickBoundaryName)
                                Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
                                    newBrick.alpha = 0.0
                                }
                        },
                            completion: { finished in
                                if finished {
                                    newBrick.removeFromSuperview()
                                    let boundarySerialNumberStartIndex = brickBoundaryName.index(
                                        brickBoundaryName.startIndex,
                                        offsetBy: BoundaryNames.brick.count
                                    )
                                    if let index = Int(brickBoundaryName[boundarySerialNumberStartIndex...]) {
                                        self?.bricks[index] = nil
                                    }
                                    self?.numberOfBricksDown += 1
                                }
                        }
                        )
                    }
                )
            }
            upperLeftPointOfNextBrick.x += brickSize.width + Constants.brickInterspace
            numberOfDrawnBricks += 1
        }
    }
    
    private func drawPaddleAndAddItsBoundary(to behavior: BreakoutBehavior) {
        deletePaddle()
        paddle = UIView(frame: CGRect(center: initialPaddleCenter, size: paddleSize))
        paddle.backgroundColor = UIColor.blue
        addSubview(paddle)
        let paddleBoundaryPath = UIBezierPath(ovalIn: paddle.frame)
        behavior.addBoundary(paddleBoundaryPath, named: BoundaryNames.paddle)
    }
    
    private func drawBalls() {
        var numberOfBallsAdded = bouncingBalls.count
        while numberOfBallsAdded < numberOfBalls {
            addBall()
            numberOfBallsAdded += 1
        }
    }
    
    func addBall() {
        let ball = BallView(frame: CGRect(center: newBallCenter, size: ballSize))
        bouncingBalls.append((ball, false))
        ball.backgroundColor = UIColor.red
        addSubview(ball)
    }
    
    func removeBall() {
        let (ball, isAnimated) = bouncingBalls.removeLast()
        ball.removeFromSuperview()
        if isAnimated {
            breakoutBehavior?.removeItem(ball)
        }
    }
    
    private func deleteBalls() {
        for (ball, _) in bouncingBalls {
            breakoutBehavior?.removeItem(ball)
            ball.removeFromSuperview()
        }
        bouncingBalls.removeAll()
    }
    
    private func deleteBricks() {
        withdrawBricksFromGameView()
        bricks.removeAll()
        numberOfBricksDown = 0
    }
    
    private func deletePaddle() {
        paddle?.removeFromSuperview()
        paddle = nil
    }
    
    private func withdrawBricksFromGameView() {
        for brick in bricks {
            brick?.removeFromSuperview()
        }
    }
    
    private var brickSize: CGSize {
        return CGSize(
            width: (bounds.width - Constants.brickInterspace * CGFloat(Constants.numberOfBrickColumns+1)) / CGFloat(Constants.numberOfBrickColumns),
            height: bounds.height * Constants.boundsHeightToBrickHeightRatio
        )
    }
    
    private var bricksOffsetFromTop: CGFloat {
        return max(Constants.bricksOffsetFromTop, bounds.height/Constants.boundsHeightToBrickOffsetFromTopRatio)
    }
    
    private var paddleSize: CGSize {
        return CGSize(
            width: brickSize.width * Constants.brickToPaddleWidthRatio,
            height: brickSize.height * Constants.brickToPaddleHeightRatio
        )
    }
    
    private var ballSize: CGSize {
        return CGSize(width: brickSize.height, height: brickSize.height)
    }
    
    private var initialPaddleCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.maxY - paddleOffsetFromBottom)
    }
    
    private var paddleOffsetFromBottom: CGFloat {
        return bounds.height * Constants.paddleOffsetFromBottomToHeightRatio
    }
    
    private var paddleCenterXValueRange: Range<CGFloat> {
        return (paddleSize.width/2)..<(bounds.width - paddleSize.width/2)
    }
    
    private var maximumAllowedPaddleTranslationAlongXAxisToTheLeft: CGFloat {
        return paddleCenterXValueRange.lowerBound - paddle.center.x
    }
    
    private var maximumAllowedPaddleTranslationAlongXAxisToTheRight: CGFloat {
        return paddleCenterXValueRange.upperBound - paddle.center.x
    }
    
    private var newBallCenter: CGPoint {
        return CGPoint(
            x: paddle?.center.x ?? bounds.midX,
            y: initialPaddleCenter.y - paddleSize.height/2 - ballSize.height/2
        )
    }
    
    // MARK: handling gestures
    func pushBalls(byReactingTo recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended, let behavior = breakoutBehavior {
            addBallsToAnimatorIfNotAlreadySo(using: behavior)
            behavior.launchBall()
        }
    }
    
    func movePaddle(byReactingTo recognizer: UIPanGestureRecognizer) {
        if paddle != nil {
            switch recognizer.state {
            case .began, .changed:
                let translationAlongXAxis = recognizer.translation(in: self).x
                recognizer.setTranslation(CGPoint.zero, in: self)
                
                let dx = translationAlongXAxis < 0 ?
                    max(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheLeft) :
                    min(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheRight)
                
                paddle.center.x += dx
                
                moveBallsWaitingOnPaddle()
                breakoutBehavior?.addBoundary(UIBezierPath(ovalIn: paddle.frame), named: BoundaryNames.paddle)
                
            default:
                break
            }
        }
    }
    
    private func addBallsToAnimatorIfNotAlreadySo(using behavior: BreakoutBehavior) {
        for (offset: index, element: (ball: ball, isAnimated: isAnimated)) in bouncingBalls.enumerated() {
            if !isAnimated {
                behavior.addItem(ball)
                bouncingBalls[index].isAnimated = true
            }
        }
    }
    
    private func moveBallsWaitingOnPaddle() {
        for (ball, isAnimated) in bouncingBalls {
            if !isAnimated {
                ball.center = newBallCenter
            }
        }
    }
    
    
    private func returnBallToPaddleIfNecessary() {
        if let behavior = breakoutBehavior, let animator = behavior.dynamicAnimator {
            for (offset: index, element: (ball: ball, isAnimated: _)) in bouncingBalls.enumerated() {
                if let gameBounds = animator.referenceView?.bounds.insetBy(dx: ball.frame.size.width/2, dy: ball.frame.size.height/2),
                    !gameBounds.contains(ball.center) {
                    ballCount = ballCount + 1
                    behavior.removeItem(ball)
                    bouncingBalls[index].isAnimated = false
                    ball.transform = CGAffineTransform.identity
                    ball.center = newBallCenter
                }
            }
        }
    }
}

extension CGRect {
    var mid: CGPoint { return CGPoint(x: midX, y: midY) }
    var upperLeft: CGPoint { return CGPoint(x: minX, y: minY) }
    var lowerLeft: CGPoint { return CGPoint(x: minX, y: maxY) }
    var upperRight: CGPoint { return CGPoint(x: maxX, y: minY) }
    var lowerRight: CGPoint { return CGPoint(x: maxX, y: maxY) }
    var midLeft: CGPoint { return CGPoint(x: minX, y: midY) }
    var midRight: CGPoint { return CGPoint(x: maxX, y: midY) }
    
    init(center: CGPoint, size: CGSize) {
        let upperLeft = CGPoint(x: center.x-size.width/2, y: center.y-size.height/2)
        self.init(origin: upperLeft, size: size)
    }
}

extension CGSize {
    func scaled(by factor: CGFloat) -> CGSize {
        return CGSize(width: width*factor, height: height*factor)
    }
}
