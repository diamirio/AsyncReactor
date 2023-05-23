//
//  RepositoryItem.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI

struct RepositoryItem: View {
    var repository: Repository
    
    var body: some View {
        NavigationLink {
            RepositoryDetailView(repository: repository)
        } label: {
            VStack {
                AsyncImage(url: URL(string: repository.owner.avatar_url)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .border(.white, width: 4)
                        .shadow(radius: 7)
                        .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                }
                
                Text(repository.full_name)
                    .font(.body)
            }
        }
        
    }
}

struct RepositoryItem_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryItem(repository: Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "", visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")))
    }
}
