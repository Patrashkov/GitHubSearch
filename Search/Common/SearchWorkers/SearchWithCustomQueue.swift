//
//  SearchWithCustomQueue.swift
//  Search
//
//  Created by Vlad on 6/23/18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import Foundation

class SearchWithCustomQueue: NSObject, SearchProtocol {
    
    private let queue = DispatchQueue(label: "com.search")
    private var tasks: [URLSessionDataTask]?
    
    private var page = 0
    private let perPage = 15
    private let language = "swift"
    
    //MARK: SearchProtocol
    func search(text: String, completion: @escaping CompletionBlock) {
        cancel()
        var results = [[Repository]]()
        var count = 0
        var finished = false
        
        let searchCompletion: CompletionBlock = { [weak self] result in
            self?.queue.sync {
                print(results)
                if let result = result { results.append(result) }
                count += 1
                finished = count == self?.page
            }
            guard finished else { return }
            
            let array = (results[0] + results[1])
            array.forEach{$0.searchName = text.removingPercentEncoding}
            completion(array.isEmpty ? array : array.sorted(by: {$0.stars > $1.stars}))
        }
        
        queue.async {
            self.tasks = [URLSessionDataTask]()
            (0..<2).forEach{_ in self.tasks?.append(self.search(with: self.request(for: text), completion: searchCompletion))}
            
            self.tasks?.forEach{$0.resume()}
        }
    }
    
    func cancel() {
        queue.async {
            self.page = 0
            self.tasks?.forEach{$0.cancel()}
            self.tasks = nil
        }
    }
    
    //MARK: Private
    private func request(for text: String) -> URLRequest {
        page += 1
        if let requestURL = URL(string: "https://api.github.com/search/repositories?q=\(text)+language:\(language)&sort=stars&per_page=\(perPage)&page=\(page)") {
            return URLRequest(url: requestURL)
        }
        fatalError("Can not generate request with URL")
    }
    
    private func search(with request: URLRequest, completion: @escaping CompletionBlock) -> URLSessionDataTask {
        return URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) in
            switch error {
            case URLError.cancelled?:
                completion(nil)
            default:
                if let jsonData = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                        if let dictJson = json as? [String : Any],
                            let iremsArray = dictJson["items"] as? [[String : Any]] {
                            DispatchQueue.main.async {
                                completion(DataModel.shared.parseListOfReposytorys(data: iremsArray))
                            }
                        }
                    } catch { completion(nil) }
                }
            }
        })
    }
}
