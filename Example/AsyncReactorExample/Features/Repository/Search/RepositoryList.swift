//
//  RepositoryList.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI

struct RepositoryList: View {
    var repositories: [Repository]
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            Spacer()
            
            LazyVGrid(columns: columns) {
                ForEach(repositories) { repository in
                    RepositoryItem(repository: repository)
                        .padding(4)
                }
            }
        }
    }
}

struct RepositoryList_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryList(repositories: [Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")), Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")), Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")), Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4"))])
    }
}
