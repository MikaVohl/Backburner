//
//  MainView.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-02.
//

import SwiftUI

struct MainView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Image("Backburner")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
                    .padding(.bottom, 60.0)
                NavigationLink("Fetch Recipe", destination: RecipeFetcherView())
                    .font(.title2)
                    .padding(.bottom, 15.0)
                NavigationLink("Browse Saved Recipes", destination: SavedRecipesBrowserView())
                    .font(.title2)
            }
            .padding(.bottom, 50.0)
            .navigationBarTitle("Backburner", displayMode: .inline)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
