//
//  CustomThemeInboxViewController.swift
//  Blueshift Inbox
//
//  Created by Ketan Shikhare on 21/04/23.
//

import UIKit
import BlueShift_iOS_SDK

class CustomThemeInboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var viewmodel: BlueshiftInboxViewModel?
    let cellIdentifier = "CustomThemeInboxTableViewCellIdentifier"
    var activityIndicatorView: UIActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        setupViewModel()
        setupActivityIndicator()
        setupTableView()
        //Fetch local cached data and show in inbox tableview
        reloadTableView()
        //Sync inbox on load
        syncInbox()
    }
    
    func setupViewModel() {
        viewmodel = BlueshiftInboxViewModel()
        self.title = "Custom Inbox"
    }
    
    func setupObservers() {
        //Add obserber to listen to inbox sync changes.
        //In case if you add pull to refresh, then you can stop the refreshAnimation in this observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name(kBSInboxUnreadMessageCountDidChange), object: nil, queue: OperationQueue.main) { [weak self] notification in
            if BlueshiftInboxChangeType.sync.rawValue == notification.userInfo?[kBSInboxRefreshType] as? UInt {
                self?.reloadTableView()
            }
        }
        //Add obserber to listen to stop activity indicator when notification is displayed
        NotificationCenter.default.addObserver(forName: NSNotification.Name(kBSInAppNotificationDidAppear), object: nil, queue: OperationQueue.main) { [weak self] notification in
            self?.activityIndicatorView?.stopAnimating()
        }
    }
    
    func setupActivityIndicator() {
        activityIndicatorView = UIActivityIndicatorView(style: .large)
        activityIndicatorView?.color = .white
        if let activityIndicatorView = activityIndicatorView {
            view.addSubview(activityIndicatorView)
            activityIndicatorView.center = view.center
        }
    }
    
    func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        //Register custom tableviewcell
        tableView.register(UINib(nibName: "CustomThemeInboxTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: cellIdentifier)
    }
    
    func syncInbox() {
        BlueshiftInboxManager.syncInboxMessages {
            //the tableview refresh will be taken care by the added observer
        }
    }
    
    func reloadTableView() {
        //Reload cached notifications and show in tableview
        viewmodel?.reloadInboxMessages(handler: { [weak self] isRefresh in
            if isRefresh {
                self?.tableView.reloadData()
            }
        })
    }
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewmodel?.numberOfSections() ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewmodel?.numberOfItems(inSection: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return createTableViewCellFor(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleDidSelectRowAt(indexPath: indexPath)
    }
        
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            handleDeleteMessageAt(indexPath: indexPath)
        }
    }
}

extension CustomThemeInboxViewController {
    func createTableViewCellFor(indexPath: IndexPath) -> UITableViewCell {
        let message: BlueshiftInboxMessage? = viewmodel?.item(at: indexPath) ?? nil
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BlueshiftInboxTableViewCell
        if let inboxCell = cell {
            inboxCell.titleLabel.text = message?.title
            inboxCell.detailLabel.text = message?.detail
            inboxCell.dateLabel.text = viewmodel?.getDefaultFormatDate(message?.createdAtDate ?? Date())
            inboxCell.setIconImageURL(message?.iconImageURL ?? nil)
            inboxCell.unreadBadgeView.isHidden = message?.readStatus ?? false
            return inboxCell
        }
        return UITableViewCell()
    }
    
    func handleDidSelectRowAt(indexPath: IndexPath) {
        let message: BlueshiftInboxMessage = viewmodel?.item(at: indexPath) ?? BlueshiftInboxMessage()
        message.readStatus = true
        self.activityIndicatorView?.startAnimating()
        tableView.reloadRows(at: [indexPath], with: .automatic)
        BlueshiftInboxManager.showNotification(for: message);
    }
    
    func handleDeleteMessageAt(indexPath: IndexPath) {
        let message: BlueshiftInboxMessage? = viewmodel?.item(at: indexPath) ?? nil
        BlueshiftInboxManager.delete(message) { [weak self]result in
            DispatchQueue.main.async {
                self?.reloadTableView()
            }
        }
    }
}
