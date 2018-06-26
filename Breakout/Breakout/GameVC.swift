//
//  ViewController.swift
//  Breakout
//
//  Created by Pavan Kulhalli on 03/04/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class GameVC: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var gameView: GameView!
    
    private var breakoutBehavior = BreakoutBehavior()
    private lazy var animator: UIDynamicAnimator = {
        let animator = UIDynamicAnimator(referenceView: self.gameView)
        animator.addBehavior(self.breakoutBehavior)
        return animator
    }()
    
    var score: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        animator.delegate = self as? UIDynamicAnimatorDelegate
        
        // Get notification about the ball being hit to bricks. Hence further increament the score
        NotificationCenter.default.addObserver(self, selector: #selector(scoreUpdater), name: Notification.Name("scoreUpdater"), object: nil)
        // Get notification once all the bricks are eliminated. Hence further setting the score to zero
         NotificationCenter.default.addObserver(self, selector: #selector(newGame), name: Notification.Name("newGame"), object: nil)
        
        initUI()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.setScore), userInfo: nil, repeats: true)
    }

    @objc func setScore()
    {
        scoreLabel.text = "Score: \(score) Ball Used: \(gameView.ballCount)"
    }
    
    // MARK: - view life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        animator.addBehavior(breakoutBehavior)
        refreshSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        animator.removeBehavior(breakoutBehavior)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if gameView != nil, gameView.frame.size != view.bounds.size {
            gameView.frame = self.view.bounds
            gameView.redrawGameViewUponRotation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initUI(){
            gameView.initGameView(frame: gameView.frame, breakoutBehavior: breakoutBehavior, ballCount: UserDefaultsManager.numberOfBalls ?? 5, brickCount: UserDefaultsManager.numberOfBricks ?? 20, ballBounciness: CGFloat(UserDefaultsManager.ballBounciness ?? 1.0))
        scoreLabel.text = "Score: 0 Ball Used: 0"
    }
    
    private func refreshSettings() {
        score = 0;
        gameView.ballCount = 1;
        gameView.set(
            ballCount: UserDefaultsManager.numberOfBalls ?? 5,
            brickCount: UserDefaultsManager.numberOfBricks ?? 20,
            bounciness: CGFloat(UserDefaultsManager.ballBounciness ?? 1.0)
        )
    }
    

    @IBAction func movePaddleGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        gameView.movePaddle(byReactingTo: sender)
    }
    
    @IBAction func launchBallGestureRecognizer(_ sender: UITapGestureRecognizer) {
        gameView.pushBalls(byReactingTo: sender)
    }
    
    @objc private func scoreUpdater(notification: NSNotification) {
        score = score + 1
    }
    @objc private func newGame(notification: NSNotification) {
        score = 0
    }
    
}

class BallView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.red
        layer.cornerRadius = frame.size.width / 2.0
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}

class BricksView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.randomColor
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .rectangle
    }
}


extension UIColor {
    static var randomColor: UIColor {
        let randomHue = CGFloat(arc4random()) / CGFloat(Int32.max)
        return UIColor(hue: randomHue, saturation: 1.0, brightness: 1.0, alpha: 0.5)
    }
}

