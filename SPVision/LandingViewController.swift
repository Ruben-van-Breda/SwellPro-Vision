//
//  LandingViewController.swift
//  SPVision
//
//  Created by Ruben van Breda on 2020/09/05.
//  Copyright © 2020 Ruben van Breda. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {
    
    var menuOut = false
    @IBOutlet weak var menu_leading: NSLayoutConstraint!
    
    @IBOutlet weak var menu_trailing: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func menuTapped(_ sender: Any) {
        print("Menu Tapped \(menuOut)")
        if menuOut == true {
            menu_leading.constant = 0
            menu_trailing.constant = 220
            menuOut = false
        }
        else {
            menu_leading.constant = -450
            menu_trailing.constant = 600
            menuOut = true
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (animationCompleted) in
            
        }
    }
    
//

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
