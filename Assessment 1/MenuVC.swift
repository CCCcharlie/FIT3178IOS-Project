//
//  MenuVC.swift
//  Assessment 1
//
//  Created by Cly Cly on 25/4/2024.
//

import Foundation
import UIKit
class MenuVC: UIViewController {

    @IBOutlet weak var menuTitleLabel: UILabel!
    @IBOutlet weak var menutitle: UILabel!
    var buttonTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题为按钮的标题
        if let title = buttonTitle {
            menutitle.text = title
        }
        
        // Do any additional setup after loading the view.
    }

}
