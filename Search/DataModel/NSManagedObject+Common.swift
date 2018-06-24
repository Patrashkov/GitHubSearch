//
//  NSManagedObject+Common.swift
//
//
//  Created by Vlad on 6/23/18.
//  Copyright © 2018. All rights reserved.
//

import Foundation
import CoreData

/*
 @discussion
 - perhaps parse func should throw errer, in case required fields are missing?
 - since date formatter is uniform and is used quite often, it makes sense to make it static
    TODO: find a place for static date formatter to reside
 */

protocol ModelMapper {
    
    static var entityName: String { get }
    static var idKey: String { get }
    
    func parse(node: Dictionary<AnyHashable, Any>)
    static func fetchRequest(id: Int32) -> NSFetchRequest<NSFetchRequestResult>
    static func fetchRequest(stringId: String) -> NSFetchRequest<NSFetchRequestResult>
}

extension ModelMapper {
    static func fetchRequest(id: Int32) -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        //Need owerwrite if your entity have  Int id
    }
    
    static func fetchRequest(stringId: String) -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        //Need owerwrite if your entity have String id
    }
}
