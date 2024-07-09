//
//  Recipe.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-01.
//

import Foundation

struct Recipe: Codable, Hashable {
    var host: String
    var title: String
    var total_time: Int
    var image: String
    var ingredients: [String]
    var ingredient_groups: [IngredientGroup]
    var instructions: String
    var instructions_list: [String]
    var yields: String
    var url: String
    var local_image: String?
//    let json: String
//    let links: [String]
//    let nutrients: [String: String]
//    let canonical_url: String
//    let equipment: [String]
//    let cooking_method: String
//    let keywords: [String]
//    let dietary_restrictions: [String]
}

struct IngredientGroup: Codable, Hashable {
    var ingredients: [String]
    var purpose: String?
}

//struct Link: Codable {
//    let `class`: [String]
//    let href: String
//    let title: String?
//    let dataTestid: String?
//    let style: String?
//
//    private enum CodingKeys: String, CodingKey {
//        case `class`
//        case href
//        case title
//        case dataTestid = "data-testid"
//        case style
//    }
//}
