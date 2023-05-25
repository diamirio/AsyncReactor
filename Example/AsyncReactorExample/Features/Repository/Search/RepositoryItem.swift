//
//  RepositoryItem.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI
import AsyncReactor

struct RepositoryItem: View {
    var repository: Repository
    
    var body: some View {
        NavigationLink {
            ReactorView(RepositoryDetailReactor()) {
                RepositoryDetailView(repository: repository)
            }
        } label: {
            HStack {
                AsyncImage(url: URL(string: repository.owner.avatarUrl)) { image in
                    image
                        .resizable()
                        .frame(width: 50, height: 50)
                        .scaledToFit()
                        .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                }
                
                Text(repository.fullName)
                    .font(.body)
            }
        }
    }
}

struct RepositoryItem_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryItem(repository: Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "", htmlUrl: "google.com", visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4")))
    }
}
