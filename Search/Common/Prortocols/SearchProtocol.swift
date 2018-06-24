//
//  SearchProtocol.swift
//  Search
//
//  Created by Vlad on 6/24/18.
//  Copyright © 2018 Vlad. All rights reserved.
//

import Foundation

typealias CompletionBlock = (([Repository]?) -> Void)

protocol SearchProtocol {
    func search(text: String, completion: @escaping CompletionBlock)
    func cancel()
}
