//
//  SearchWithSessions.swift
//  Search
//
//  Created by Vlad on 6/23/18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import Foundation
/// @discussion
/// Причина реалізації пошуку за допомогою двух URLSessions:
/// В документаціїї Apple по "URLSession.shared" сказано що вона е серійною,
/// а в завдані, було вказано про 2 потока,
/// тобто якщо ми скористаемось одніею сесіею буде один серійний потік
/// тому я вирішив додати що пошук з двома URLSession

class SearchWithSessions: NSObject, SearchProtocol  {
    
    private var firstSession: URLSession = URLSession(configuration: .default,
                                                      delegate: nil,
                                                      delegateQueue: OperationQueue())
    
    private var secondSession: URLSession = URLSession(configuration: .default,
                                                       delegate: nil,
                                                       delegateQueue: OperationQueue())
    private var page = 0
    private let perPage = 15
    private let language = "swift"
    private var tasks: (first: URLSessionDataTask, second: URLSessionDataTask)?
    
    //MARK: SearchProtocol
    func search(text: String, completion: @escaping CompletionBlock) {
        cancel()
        let group = DispatchGroup()
        var results = [[Repository]]()
        
        let parseCompletion: ((Data?, URLResponse?, Error?) -> Void) = { data, _, error in
            guard error == nil else { return group.leave() }
            do {
                guard let data = data else { return group.leave() }
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                if let dictJson = json as? [String : Any],
                    let iremsArray = dictJson["items"] as? [[String : Any]] {
                    DispatchQueue.main.async {
                        results.append(DataModel.shared.parseListOfReposytorys(data: iremsArray))
                        group.leave()
                    }
                }
            } catch { group.leave() }
        }
        
        tasks = (firstSession.dataTask(with: request(for: text), completionHandler: parseCompletion),
                 secondSession.dataTask(with: request(for: text), completionHandler: parseCompletion))
        
        (0..<page).forEach{_ in group.enter()}
        tasks?.first.resume()
        tasks?.second.resume()
        group.notify(queue: .global()) {
            let sortedArray = (results[0] + results[1]).sorted(by: {$0.stars > $1.stars})
            sortedArray.forEach{$0.searchName = text.removingPercentEncoding}
            completion(sortedArray)
        }
    }
    
    func cancel() {
        page = 0
        tasks?.first.cancel()
        tasks?.second.cancel()
        tasks = nil
    }
    
    //MARK: Private
    private func request(for text: String) -> URLRequest {
        page += 1
        if let requestURL = URL(string: "https://api.github.com/search/repositories?q=\(text)+language:\(language)&sort=stars&per_page=\(perPage)&page=\(page)") {
            return URLRequest(url: requestURL)
        }
        fatalError("Can not generate request with URL")
    }
}
