//
//  SavedRecipesBrowserView.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-02.
//

import SwiftUI

struct SavedRecipesBrowserView: View {
    @State private var savedRecipes: [Recipe] = []
    @Environment(\.editMode) var editMode // Track the edit mode

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            // Use LazyVGrid with the columns defined
            LazyVGrid(columns: columns) {
                ForEach(savedRecipes.indices, id: \.self) { index in
                    var recipe = savedRecipes[index]
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            VStack {
                                if let url = URL(string: recipe.image) {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 160)
                                    .clipped()
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                }
                                Text(recipe.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .frame(width: 160, height: 50, alignment: .top)
                            }.foregroundColor(.black)
                                .overlay(
                                    DeleteButton(recipe: savedRecipes[index], recipes: $savedRecipes, onSave: saveRecipes)
                                        .offset(x: 8, y: -8) // Adjust these values as needed
                                    , alignment: .topTrailing
                                )
            
                            }
                        }
                    }
                }
            .padding() // Padding around the entire grid for spacing from screen edges
            .onAppear {
                loadSavedRecipes()
            }
        }
        .navigationBarTitle("Saved Recipes", displayMode: .inline)
        .toolbar {
            EditButton()
        }
    }

    func loadSavedRecipes() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recipesFileURL = documentsDirectory.appendingPathComponent("recipes.json")

        do {
            let data = try Data(contentsOf: recipesFileURL)
            let decoder = JSONDecoder()
            savedRecipes = try decoder.decode([Recipe].self, from: data)
        } catch {
            print("Error loading saved recipes: \(error)")
        }
    }

    func saveRecipes() {
        print("saving recipes")
        print(savedRecipes)
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let recipesFileURL = documentsDirectory.appendingPathComponent("recipes.json")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedRecipes)
            try data.write(to: recipesFileURL)
        } catch {
            print("Error saving recipes: \(error)")
        }
    }

}


struct DeleteButton: View {
    @Environment(\.editMode) var editMode
    
    let recipe: Recipe
    @Binding var recipes: [Recipe]
    let onSave: () -> Void
    
    var body: some View {
        if editMode?.wrappedValue.isEditing ?? false {
            Button(action: {
                if let index = recipes.firstIndex(where: { $0.title == recipe.title }) {
                    deleteRecipe(at: index)
                }
                onSave()
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
    
    func deleteRecipe(at index: Int) {
        // Remove the recipe from the savedRecipes array
        recipes.remove(at: index)
    }
}
