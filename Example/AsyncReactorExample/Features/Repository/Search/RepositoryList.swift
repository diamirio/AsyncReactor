//
//  RepositoryList.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI

struct RepositoryList: View {
    var repositories: [Repository]
    
    var body: some View {
        ForEach(repositories) { repository in
            RepositoryItem(repository: repository)
                .padding(4)
        }
    }
}

struct RepositoryList_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryList(repositories: [
            Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "",htmlUrl: "google.com",watchersCount: 1, forks: 1, visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "",htmlUrl: "google.com",watchersCount: 1, forks: 1, visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "",htmlUrl: "google.com",watchersCount: 1, forks: 1, visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "", htmlUrl: "google.com",watchersCount: 1, forks: 1,visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4"))
        ])
    }
}
