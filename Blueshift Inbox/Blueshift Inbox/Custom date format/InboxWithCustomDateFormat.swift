//
//  CustomDateFormat.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 11/01/23.
//

import Foundation
import BlueShift_iOS_SDK

extension ViewController {
    @IBAction private func showInboxWithCustomDateFormat(_ sender: Any) {
        let navController = BlueshiftInboxNavigationViewController()
        navController.inboxDelegate = CustomDateFormatterInboxDelegate()
        navController.title = "Inbox with Date format"
        self.present(navController, animated:true, completion: nil)
    }
}


public class CustomDateFormatterInboxDelegate: NSObject, BlueshiftInboxViewControllerDelegate {
    
    public func formatDate(_ message: BlueshiftInboxMessage) -> String? {
        guard let createdAt = message.createdAtDate else {
            return nil
        }
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: createdAt, relativeTo: Date())
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy hh:mm aa"
            return dateFormatter.string(from: createdAt)
        }
    }
}
