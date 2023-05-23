//
//  RepositoryDetailView.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI

struct RepositoryDetailView: View {
    @EnvironmentObject
    private var reactor: RepositoryDetailReactor
    
    var repository: Repository
    
    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: repository.owner.avatar_url)) { image in
                image
                    .resizable()
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 4)
                    }
                    .shadow(radius: 7)
                    .scaledToFit()
                    .frame(height: 200)
            } placeholder: {
                ProgressView()
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text(repository.name)
                        .font(.title2)
                    
                    Spacer()
                    
                    Label("Visibility", systemImage: repository.visibility.lowercased() == "public" ? "lock.open" : "lock")
                        .labelStyle(.iconOnly)
                        .foregroundColor(repository.visibility.lowercased() == "public" ? Color.green : Color.red)
                }
                
                Divider()
                
                if repository.description != nil {
                    Text(repository.description!)
                        .font(.body)
                }
            }
            
            Spacer()
        }
        .padding()
        
    }
}

struct RepositoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RepositoryDetailView(repository: Repository(id: 0, name: "Test Repo", full_name: "github/Test Repo", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse ultricies nisi elit, non imperdiet nibh euismod in. Sed sit amet tincidunt arcu, nec ornare nisl. Pellentesque sollicitudin quam quis elit tempus, et interdum lorem tristique. Nunc rhoncus ornare efficitur. Ut tellus libero, pretium sit amet dolor a, maximus scelerisque sem. Phasellus posuere aliquam purus. Mauris justo tellus, molestie ut eros at, lobortis luctus nulla. Nullam libero leo, sagittis ac orci nec, viverra faucibus lacus. Phasellus faucibus ipsum nec velit mattis tincidunt. Phasellus nulla mauris, lobortis ac quam non, consectetur viverra odio. Praesent sed venenatis nulla. Praesent non maximus sem, quis ultricies ligula. Aliquam eleifend non velit eget venenatis. Vivamus aliquet, nisl vestibulum cursus aliquet, neque justo feugiat magna, eu suscipit turpis mi id orci.",
                                              
 visibility: "public", owner: Repository.Owner(avatar_url: "https://avatars.githubusercontent.com/u/60294?v=4")))
    }
}
