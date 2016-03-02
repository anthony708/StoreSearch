//
//  MenuViewController.swift
//  StoreSearch
//
//  Created by ZhuDuan on 16/3/2.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit

protocol MenuViewControllerDelegate: class {
    func menuViewControllerSendSupportEmail(_: MenuViewController)
}

class MenuViewController: UITableViewController {

    weak var delegate: MenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.row == 0 {
            delegate?.menuViewControllerSendSupportEmail(self)
        }
    }
}
