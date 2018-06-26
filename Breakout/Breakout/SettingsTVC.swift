//
//  SettingsTVC.swift
//  Breakout
//
//  Created by Pavan Kulhalli on 03/04/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController {

    @IBOutlet weak var ballsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var bricksLabel: UILabel!
    @IBOutlet weak var bricksStepper: UIStepper!
    @IBOutlet weak var bouncinessSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView() 
        getSavedSettings()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    @IBAction func ballsValueChanged(_ sender: UISegmentedControl) {
        UserDefaultsManager.numberOfBalls = sender.selectedSegmentIndex + 1
    }
    
    @IBAction func bricksValueChanged(_ sender: UIStepper) {
        bricksLabel?.text = String(Int(sender.value))
        UserDefaultsManager.numberOfBricks = Int(sender.value)
    }
    
    @IBAction func bouncinessValueChanged(_ sender: UISlider) {
        UserDefaultsManager.ballBounciness = sender.value
    }
    
    private func getSavedSettings() {
        ballsSegmentedControl.selectedSegmentIndex = (UserDefaultsManager.numberOfBalls ?? 1) - 1
        bricksStepper.value = Double(UserDefaultsManager.numberOfBricks ?? 5)
        bricksLabel.text = String(Int(bricksStepper.value))
        bouncinessSlider.value = UserDefaultsManager.ballBounciness ?? 1.0
    }

}
