//
//  RepositoryDetailView.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 22.05.23.
//

import SwiftUI
import AsyncReactor

struct RepositoryDetailView: View {
    @EnvironmentObject
    private var reactor: RepositoryDetailReactor
    
    var repository: Repository
    
    @ActionBinding(RepositoryDetailReactor.self, keyPath: \.sheetPresented, action: RepositoryDetailReactor.Action.setSheetPresented)
    private var sheetPresented: Bool
    
    var body: some View {
        ScrollView {
            AsyncImage(url: URL(string: repository.owner.avatarUrl)) { image in
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
                    
                    Label("Visibility", systemImage: repository.isVisible ? "lock.open" : "lock")
                        .labelStyle(.iconOnly)
                        .foregroundColor(repository.isVisible ? Color.green : Color.red)
                }
                
                Divider()
                
                Button("Show Description") {
                    reactor.send(.setSheetPresented(true))
                }
                .disabled(reactor.longRunningActionRunning)
                
                Spacer()
                
                Button("Long running action") {
                    reactor.send(.longRunningAction, id: .init(id: "longRunning", mode: [.lifecycle, .inFlight]))
                }
                
                if reactor.longRunningActionRunning {
                    ProgressView()
                }
            }
        }
        .padding(.horizontal)
        .toolbar {
            Link(destination: URL(string: repository.htmlUrl)!) {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .sheet(isPresented: $sheetPresented) {
            NavigationStack {
                RepositoryDescriptionSheet(description: repository.description ?? "")
            }
        }
    }
}

struct RepositoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RepositoryDetailView(repository: Repository(id: 0, name: "Test Repo", fullName: "github/Test Repo", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse ultricies nisi elit, non imperdiet nibh euismod in. Sed sit amet tincidunt arcu, nec ornare nisl. Pellentesque sollicitudin quam quis elit tempus, et interdum lorem tristique. Nunc rhoncus ornare efficitur. Ut tellus libero, pretium sit amet dolor a, maximus scelerisque sem. Phasellus posuere aliquam purus. Mauris justo tellus, molestie ut eros at, lobortis luctus nulla. Nullam libero leo, sagittis ac orci nec, viverra faucibus lacus. Phasellus faucibus ipsum nec velit mattis tincidunt. Phasellus nulla mauris, lobortis ac quam non, consectetur viverra odio. Praesent sed venenatis nulla. Praesent non maximus sem, quis ultricies ligula. Aliquam eleifend non velit eget venenatis. Vivamus aliquet, nisl vestibulum cursus aliquet, neque justo feugiat magna, eu suscipit turpis mi id orci.", htmlUrl: "google.com",watchersCount: 1, forks: 1, visibility: "public", owner: Repository.Owner(avatarUrl: "https://avatars.githubusercontent.com/u/60294?v=4")))
        }
        .environmentObject(RepositoryDetailReactor())
    }
}
