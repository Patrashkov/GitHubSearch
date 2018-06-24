//
//  Repository+CoreDataClass.swift
//  Search
//
//  Created by Vlad on 6/24/18.
//  Copyright © 2018 Vlad. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Repository)
public class Repository: NSManagedObject, ModelMapper {
    static var idKey: String {
        return "repositoryId"
    }
    
    static var entityName: String {
        return "Repository"
    }
    static func fetchRequest(id: Int32) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest:NSFetchRequest<Repository> = Repository.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(idKey) == '\(id)'")
        
        return fetchRequest as! NSFetchRequest<NSFetchRequestResult>
    }
    
    func parse(node: Dictionary<AnyHashable, Any>) {
        
        if let id = node["id"] as? Int32 {
            repositoryId = id
        }
        
        if let stringUrl = node["html_url"] as? String,
            let nodeURL = URL(string: stringUrl) {
            url = nodeURL
        }
        
        if let rating = node["stargazers_count"] as? Double {
            stars = rating
        }
        
        if let fullName = node["full_name"] as? String {
            name = fullName.count > 30 ? String(fullName.prefix(30) + "...") : fullName
        }
    }
}
