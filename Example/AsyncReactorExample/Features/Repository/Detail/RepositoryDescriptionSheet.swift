//
//  RepositoryDescriptionSheet.swift
//  AsyncReactorExample
//
//  Created by Ahmet Bozkan on 23.05.23.
//

import SwiftUI

struct RepositoryDescriptionSheet: View {
    var description: String
    
    var body: some View {
        Text(description)
            .padding()
    }
}

#Preview {
    RepositoryDescriptionSheet(description: "Description")
}
