//
//  Repository+CoreDataProperties.swift
//  Search
//
//  Created by Vlad on 6/24/18.
//  Copyright © 2018 Vlad. All rights reserved.
//
//

import Foundation
import CoreData


extension Repository {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Repository> {
        return NSFetchRequest<Repository>(entityName: "Repository")
    }

    @NSManaged public var name: String?
    @NSManaged public var repositoryId: Int32
    @NSManaged public var searchName: String?
    @NSManaged public var stars: Double
    @NSManaged public var url: URL?

}
