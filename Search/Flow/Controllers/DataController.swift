//
//  DataController.swift
//  Search
//
//  Created by Vlad on 6/24/18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import UIKit

class DataController: UIViewController {
    
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    
    private enum SearchType: Int {
        case dispatchQueue = 0
        case dispatchGroup
        case none
        
        init?(type: Int) {
            switch type {
            case 0: self = .dispatchQueue
            case 1: self = .dispatchGroup
            default: self = .none
            }
        }
    }
    
    private var searchType: SearchType? = .dispatchQueue
    private var popupType: PopupController.PopupType?
    private let popupSegueId = "showPopup"
    private var dataSource: [Repository]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    private var selectedURL: URL?
    
    private lazy var queueSearch: SearchWithCustomQueue = SearchWithCustomQueue()
    private lazy var sessionSearch: SearchWithSessions = SearchWithSessions()
    
    private var searchHalper: SearchProtocol {
        return searchType == .dispatchQueue ? queueSearch : sessionSearch
    }
    
    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
    }
    
    //MARK: Actions
    @IBAction func searcHControllChanged(_ sender: UISegmentedControl) {
        searchType = SearchType(type: sender.selectedSegmentIndex)
    }
    
    @IBAction func showwistoryButtonPressed(_ sender: Any?) {
        popupType = .history
        performSegue(withIdentifier: popupSegueId, sender: self)
    }
    
    @IBAction func cancelAllTasksPressed(_ sender: UIBarButtonItem) {
        searchHalper.cancel()
    }
    
    //MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == popupSegueId {
            let destinationVC = segue.destination as? PopupController
            destinationVC?.configuration = PopupController.ScreenConfiguration(type: popupType,
                                                                               repositoryUrl: selectedURL,
                                                                               delegate: self)
            
        }
    }
}

//MARK: UITableViewDataSource, UITableViewDelegate
extension DataController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = dataSource?[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        popupType = .webView
        if let url = dataSource?[indexPath.row].url {
            selectedURL = url
            performSegue(withIdentifier: popupSegueId, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: UISearchBarDelegate
extension DataController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, let seatchText = text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)  else { return }
        dataSource = nil
        searchBar.resignFirstResponder()
        searchHalper.search(text: seatchText) {[weak self] (results) in
            DispatchQueue.main.async {
                self?.dataSource = results
                DataModel.shared.saveContext()
            }
        }
    }
}

//MARK: PopupControllerDelegate
extension DataController: PopupControllerDelegate {
    func selectedHistory(name: String, dataSource: [Repository]?) {
        searchBar.text = name
        self.dataSource = dataSource
    }
}
