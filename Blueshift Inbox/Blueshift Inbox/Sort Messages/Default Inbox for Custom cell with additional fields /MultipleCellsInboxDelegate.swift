//
//  MultipleCellsInboxDelegate.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

public class MultipleCellsInboxDelegate: NSObject, BlueshiftInboxViewControllerDelegate {
    public var customCellNibNames: [String]? = ["OfferInboxTableViewCell", "CustomInboxTableViewCell"]
    
   public func getCustomCellNibName(for message: BlueshiftInboxMessage) -> String? {
       let value = Int(message.createdAtDate?.timeIntervalSince1970 ?? 0) % 3
       if (value == 0) {
           return "OfferInboxTableViewCell"
       } else if(value == 1) {
           return "CustomInboxTableViewCell"
       } else {
           return nil
       }
    }
}

extension ViewController {
    
    
}
