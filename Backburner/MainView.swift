//
//  MainView.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-02.
//

import SwiftUI

struct MainView: View {
    
    var body: some View {
        NavigationStack() {
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

// TODO:
// - Dynamic ingredient amounts to allow for scaling (double recipe, half recipe, ...)
// - Modularized ingredients to allow for unit conversions (cups -> grams, liters -> ml, ...)
// - Accept links from apple's share dialog
