//
//  InboxUsingNavController.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func  showDefaultInboxUsingNavigationController(_ sender: Any) {
        let navController = BlueshiftInboxNavigationViewController()
        //customization
        navController.unreadBadgeColor = UIColor.blue
        navController.refreshControlColor = UIColor.systemPink
        navController.showDoneButton = false
        navController.title = "Default Inbox"
        navController.enableLargeTitle = true
        self.present(navController, animated:true, completion: nil)
    }
}
