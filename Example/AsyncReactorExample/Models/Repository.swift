//
//  Github.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import Foundation

struct Repository: Decodable, Identifiable, Hashable {
    var id: Int
    let name: String
    let fullName: String
    let description: String?
    let htmlUrl: String
    let watchersCount: Int
    let forks: Int
    
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
    
    struct Owner: Decodable, Hashable {
        var avatarUrl: String
        
        enum CodingKeys: String, CodingKey {
            case avatarUrl = "avatar_url"
        }
    }
    
    enum CodingKeys : String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case htmlUrl = "html_url"
        case visibility
        case owner
        case watchersCount = "watchers_count"
        case forks
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
