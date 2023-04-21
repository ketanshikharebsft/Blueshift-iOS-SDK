//
//  InboxWithCustomCellAsDefault.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func showInboxWithCustomCellAsDefaultCell(_ sender: Any) {
        let navController = BlueshiftInboxNavigationViewController()
        navController.customCellNibName = "CustomInboxTableViewCell"
        navController.title = "Custom cell Inbox"
        self.present(navController, animated:true, completion: nil)
    }
}
