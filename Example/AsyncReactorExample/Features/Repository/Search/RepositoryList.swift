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
            Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "",html_url: "google.com", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "",html_url: "google.com", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "",html_url: "google.com", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")),
            Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", html_url: "google.com",visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4"))
        ])
    }
}
