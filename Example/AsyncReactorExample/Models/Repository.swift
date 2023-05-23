//
//  Github.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import Foundation

struct Repository: Decodable, Identifiable {
    var id: Int
    let name: String
    let full_name: String
    let description: String?
    let html_url: String
    
    let visibility: String
    var isVisible: Bool {
        if visibility.lowercased() == "public" {
            return true
        }
        else {
            return false
        }
    }
    
    var owner: Owner
    struct Owner: Decodable {
        var avatar_url: String
    }
}

struct RepositoriesResponse: Decodable {

    let totalCount: Int
    let repositories: [Repository]
    var nextPage: URL?

    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case repositories = "items"
        case nextPage = "next_page"
    }
}
