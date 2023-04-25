//
//  InboxUsingNavController.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

/// Using this method, you can create the inbox using the navigation controller.
/// You can use this way to add the deep linked screen to the same navigation stack
/// and dismiss the navigation controller when the job is done.

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func  showDefaultInboxUsingNavigationController(_ sender: Any) {
        //Create Blueshift inbox navigation controller object
        let navController = BlueshiftInboxNavigationViewController()
        //customization
        navController.unreadBadgeColor = UIColor.blue
        navController.refreshControlColor = UIColor.systemPink
        navController.showDoneButton = false
        navController.title = "Default Inbox"
        navController.enableLargeTitle = true
        //present 
        self.present(navController, animated:true, completion: nil)
    }
}
