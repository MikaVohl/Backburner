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
                    let recipe = savedRecipes[index]
                    let imageURLString = recipe.local_image
                    
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            VStack {
                                if let imageURLString = imageURLString {
                                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                    let imageURL = documentsDirectory.appendingPathComponent("images/"+imageURLString)
                                    
                                    if FileManager.default.fileExists(atPath: imageURL.path) {
                                        if let uiImage = UIImage(contentsOfFile: imageURL.path) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 160, height: 160)
                                                .clipped()
                                                .cornerRadius(10)
                                                .shadow(radius: 2)
                                        } else {
                                            Text("Image not found")
                                        }
                                    } else {
                                        Text("Image not found2")
                                    }
                                } else {
                                    Text("No image URL")
                                }
                                
                                Text(recipe.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .frame(width: 160, height: 50, alignment: .top)
                            }
                            .onAppear {
                                if let imageURLString = imageURLString {
                                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                    let imageURL = documentsDirectory.appendingPathComponent(imageURLString)
                                    print("Documents Directory: \(documentsDirectory.path)")
                                    print("Image URL: \(imageURL.path)")
                                    print("File exists at path: \(FileManager.default.fileExists(atPath: imageURL.path))")
                                }
                            }
                            .foregroundColor(.black)
                            }.overlay(
                                DeleteButton(recipe: savedRecipes[index], recipes: $savedRecipes, onSave: saveRecipes)
                                    .offset(x: 8, y: -8) // Adjust these values as needed
                                , alignment: .topTrailing
                            )
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
