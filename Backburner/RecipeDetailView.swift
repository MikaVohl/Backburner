//
//  RecipeDetailView.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-02.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    @State private var selectedIngredients = Set<String>()
    @State private var selectedInstructions = Set<Int>()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.title)
                    .font(.largeTitle)
                    .padding(.bottom)
                
                if let url = recipe.canonical_url, let origin_link = URL(string: url){
                    Link("Source Link from \(recipe.host)", destination: origin_link)
                }
                
                Text("Yields: \(recipe.yields)")
                let total_time = recipe.total_time
                let hours = total_time / 60
                let minutes = total_time % 60
                if hours > 0 && minutes > 0 {
                    Text("Total Time: \(hours) hours and \(minutes) minutes")
                }else if hours > 0 {
                    Text("Total Time: \(hours) hours")
                }else if minutes > 0 {
                    Text("Total Time: \(minutes) minutes")
                }
                

                let imageUrl = recipe.image
                if let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                }

                Text("Ingredients")
                    .font(.title)

                ForEach(recipe.ingredient_groups, id: \.self) { group in
                    if let purpose = group.purpose {
                        Text(purpose)
                            .font(.headline)
                    }
                    ForEach(group.ingredients, id: \.self) { ingredient in
                        Text("• \(ingredient)")
                            .strikethrough(self.selectedIngredients.contains(ingredient), color: .black)
                            .onTapGesture {
                                if self.selectedIngredients.contains(ingredient) {
                                    self.selectedIngredients.remove(ingredient)
                                } else {
                                    self.selectedIngredients.insert(ingredient)
                                }
                            }
                    }
                }

                Text("Instructions")
                    .font(.title)
                    .padding(.top)

//                Text(recipe.instructions)
//                ForEach(recipe.instructions_list, id: \.self) { instruction in
//                    Text("• \(instruction)")
//                }
                ForEach(Array(recipe.instructions_list.enumerated()), id: \.element) { index, instruction in
                    Text("\(index + 1). \(instruction)")
                        .strikethrough(self.selectedInstructions.contains(index), color: .black)
                            .onTapGesture {
                                if self.selectedInstructions.contains(index) {
                                    self.selectedInstructions.remove(index)
                                } else {
                                    self.selectedInstructions.insert(index)
                                }
                            }
                }
            }
            .padding()
        }
        .navigationBarTitle(recipe.title, displayMode: .inline)
    }
}
