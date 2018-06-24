//
//  PopupController.swift
//  Search
//
//  Created by Vlad on 6/24/18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import UIKit
import WebKit

protocol PopupControllerDelegate: class {
    func selectedHistory(name: String, dataSource: [Repository]?)
}

class PopupController: UIViewController {
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var tableView: UITableView!
    
    private var dataSource: [String]?

    enum PopupType {
        case webView
        case history
    }
    
    struct ScreenConfiguration {
        var type: PopupType? = .webView
        var repositoryUrl: URL?
        weak var delegate: PopupControllerDelegate?
    }
    
    var configuration: ScreenConfiguration?
    
    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        switch configuration?.type {
        case .webView?:
            if let url = configuration?.repositoryUrl {
                webView.navigationDelegate = self
                activityIndicator.startAnimating()
                webView.load(URLRequest(url: url))
            }
        case .history?:
            if let result = DataModel.shared.getHistoryList() {
                tableView.isHidden = false
                dataSource = result
                tableView.reloadData()
            }
        default: break
        }
    }
    
    //MARK: Actions
    @IBAction func closeButoonPressed(_ sender: Any? = nil) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: UITableViewDataSource, UITableViewDelegate
extension PopupController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let name = dataSource?[indexPath.row] else { return UITableViewCell() }
        let cell = UITableViewCell()
        cell.textLabel?.text = name.isEmpty ? "Most popular repository" : name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let searchName = dataSource?[indexPath.row] else { return }
        DispatchQueue.main.async {
            self.configuration?.delegate?.selectedHistory(name: historyName,
                                                          dataSource: DataModel.shared.getResultBySearchName(searchName))
            self.closeButoonPressed()
        }
    }
}

//MARK: WKNavigationDelegate
extension PopupController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
