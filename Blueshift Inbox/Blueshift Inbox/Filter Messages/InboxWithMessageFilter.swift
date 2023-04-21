//
//  InboxWithMessageFilter.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func showInboxWithMessageFilter(_ sender:Any) {
        let navController = BlueshiftInboxNavigationViewController()
        navController.inboxDelegate = MessageFilterInboxDelgate()
        navController.title = "Inbox with message filter"
        self.present(navController, animated:true, completion: nil)
    }
}

public class MessageFilterInboxDelgate: NSObject, BlueshiftInboxViewControllerDelegate {
    // Filter to show only Unread messages
    public var messageFilter: ((BlueshiftInboxMessage) -> Bool)? = { message in
        return !message.readStatus
    }
}
