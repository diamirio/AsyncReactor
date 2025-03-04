//
//  GitHubAPI.swift
//  AsyncReactorExample
//
//  Created by Dominik Arnhof on 13.07.23.
//

import SwiftUI

struct GitHubAPI {
    func search(query: String) async throws -> [Repository] {
        let (data, _) = try await URLSession.shared.data(from: URL(string:"https://api.github.com/search/repositories?q=\(query)")!)
        let decodedResponse = try JSONDecoder().decode(RepositoriesResponse.self, from: data)
        return decodedResponse.repositories
    }
}

private struct GitHubAPIKey: EnvironmentKey {
    static var defaultValue: GitHubAPI? = nil
}

extension EnvironmentValues {
    var gitHubApi: GitHubAPI? {
        get { self[GitHubAPIKey.self] }
        set { self[GitHubAPIKey.self] = newValue }
    }
}
