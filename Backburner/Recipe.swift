//
//  Recipe.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-01.
//

import Foundation

struct Recipe: Codable, Hashable {
    var id: Int?
    var tags: [String]?
    var local_image: String?
    
    // From scraper
    var host: String
    var canonical_url: String?
    var title: String
    var category: String?
    var total_time: Int
    var cook_time: Int?
    var prep_time: Int?
    var cooking_method: String?
    var yields: String
    var image: String
    var nutrients: [String: String]?
    var keywords: [String]?
    var language: String?
    var ingredients: [String]
    var ingredient_groups: [IngredientGroup]
    var instructions: String
    var instructions_list: [String]
    var ratings: Double?
    var ratings_count: Int?
    var author: String?
    var cuisine: String?
    var description: String?
    var reviews: [String]?
    var equipment: [String]?
    var dietary_restrictions: [String]?
    var site_name: String?
}

struct IngredientGroup: Codable, Hashable {
    var ingredients: [String]
    var purpose: String?
}
