//
//  InboxWithMessageSort.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func showInboxWithMessageSort(_ sender: Any) {
        let navController = BlueshiftInboxNavigationViewController()
        navController.inboxDelegate = MessageSortInboxDelegate()
        navController.title = "Inbox with message sort"
        self.present(navController, animated:true, completion: nil)
    }
}


public class MessageSortInboxDelegate: NSObject, BlueshiftInboxViewControllerDelegate {

    public var messageComparator: ((BlueshiftInboxMessage, BlueshiftInboxMessage) -> ComparisonResult)? = {msg1, msg2 in
        
        //Sort messages based on message created date
        if let date1 = msg1.createdAtDate, let date2 = msg2.createdAtDate {
            //New Messages displayed on top
            return date2.compare(date1)
            
            //Old messages displayed on top
//            return date1.compare(date2)
        }
        
        
        
//        //Sort messages based on text
//        if let msg1Title = msg1.title, let msg2Title = msg2.title {
//            return msg1Title.caseInsensitiveCompare(msg2Title)
//        }
        
        //Default return same order
        return .orderedSame
    }
}
