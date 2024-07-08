//
//  RecipeFetcherView.swift
//  Backburner
//
//  Created by Mika Vohl on 2024-07-02.
//

import SwiftUI

struct RecipeFetcherView: View {
    @State private var url: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var recipe: Recipe?
    @State private var navigateToRecipeDetail: Bool = false
    @State private var showingNamingDialog: Bool = false
    @State private var recipeName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    if let clipboard = UIPasteboard.general.string {
                        url = clipboard
                    }
                }) {
                    Text("Paste Clipboard")
                }
                
                TextField("Enter Recipe URL", text: $url)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    isLoading = true
                    fetchRecipe()
                }) {
                    Text("Fetch Recipe")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
            }
            .padding()
            .sheet(isPresented: $showingNamingDialog) {
                NamingDialog(recipeName: $recipeName) {
                    // Update the recipe title with the new name
                    self.recipe?.title = self.recipeName
                    // Attempt to save again
                    checkAndSaveRecipe()
                }
            }
            .navigationDestination(isPresented: $navigateToRecipeDetail) {
                if let recipeDetail = recipe {
                    RecipeDetailView(recipe: recipeDetail)
                } else {
                    Text("Recipe detail not available.")
                }
            }
        }
    }
    
    func fetchRecipe() {
        guard let endpointUrl = URL(string: "http://10.0.0.182:5000/scrape") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        let parameters: [String: Any] = ["url": url]
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data else {
                    errorMessage = error?.localizedDescription ?? "Unknown error"
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(Recipe.self, from: data)
                    self.recipe = decodedResponse
                    // Directly attempt to save the recipe
                    checkAndSaveRecipe()
                } catch {
                    errorMessage = "Error decoding response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func checkAndSaveRecipe() {
        guard let newRecipe = self.recipe else { return }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent("recipes.json")
        
        var recipes: [Recipe] = []
        
        if let data = try? Data(contentsOf: fileURL),
           let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decodedRecipes
        }
        if recipes.contains(where: { $0.title == newRecipe.title }) {
            var count = 1
            var uniqueTitle = "\(newRecipe.title) (\(count))"
            while recipes.contains(where: { $0.title == uniqueTitle }) {
                count += 1 // Increment count if the title is not unique
                uniqueTitle = "\(newRecipe.title) (\(count))" // Update uniqueTitle with the new count
            }
            self.recipeName = uniqueTitle
            self.showingNamingDialog = true
        } else {
            // If no conflict, save the recipe
            recipes.append(newRecipe)
            if let encodedData = try? JSONEncoder().encode(recipes) {
                try? encodedData.write(to: fileURL)
                self.navigateToRecipeDetail = true
            }
        }
    }
    
    struct NamingDialog: View {
        @Binding var recipeName: String
        var onSave: () -> Void
        
        var body: some View {
            VStack {
                Text("Recipe name already exists. Please enter a new name:")
                TextField("New Recipe Name", text: $recipeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Save") {
                    onSave()
                }
                .padding()
            }
            .padding()
        }
    }
}

// Ensure you have a Recipe struct defined somewhere in your project that conforms to Codable




//import SwiftUI
//
//struct RecipeFetcherView: View {
//    @State private var url: String = ""
//    @State private var isLoading: Bool = false
//    @State private var errorMessage: String?
//    @State private var recipe: Recipe?
//    @State private var navigateToRecipeDetail: Bool = false // State to control navigation
//    @State private var showingNamingDialog: Bool = false // For showing the naming dialog
//    @State private var recipeName: String = "" // Temporary storage for the new recipe name
//
//    var body: some View {
//        VStack {
//            Button(action: {
//                if let clipboard = UIPasteboard.general.string {
//                    url = clipboard
//                }
//            }) {
//                Text("Paste Clipboard")
//            }
//            
//            TextField("Enter Recipe URL", text: $url)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            Button(action: {
//                isLoading = true
//                fetchRecipe()
//            }) {
//                Text("Fetch Recipe")
//                    .padding()
//                    .foregroundColor(.white)
//                    .background(Color.blue)
//                    .cornerRadius(8)
//            }
//            .padding()
//
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding()
//            }
//
//            if isLoading {
//                ProgressView("Loading...")
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .padding()
//            }
//        }
//        .padding()
//        
//        // redirect to recipe detail view once fetched. May need to use a view controller for this
//    }
//
//    func fetchRecipe() {
//        guard let endpointUrl = URL(string: "http://10.0.0.182:5000/scrape") else {
//            print("Invalid URL")
//            return
//        }
//
//        let parameters: [String : Any] = ["url": url]
//        var request = URLRequest(url: endpointUrl)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async {
//                isLoading = false
//
//                guard let data = data else {
//                    if let error = error {
//                        errorMessage = "Error: \(error.localizedDescription)"
//                    } else {
//                        errorMessage = "Unknown error"
//                    }
//                    return
//                }
//
//                do {
//                    let decodedResponse = try JSONDecoder().decode(Recipe.self, from: data)
//                    self.recipe = decodedResponse
//                    checkAndSaveRecipe()
//                    navigateToRecipeDetail = true // Trigger navigation
//                } catch {
//                    errorMessage = "Error decoding response: \(error.localizedDescription)"
//                }
//            }
//        }.resume()
//        DispatchQueue.main.async {
//            self.showingNamingDialog = true
//        }
//    }
//    
//    func checkAndSaveRecipe() {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted // Optional, for better readability of the saved JSON
//        
//        do {
//            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let fileURL = documentDirectory.appendingPathComponent("recipes.json")
//            
//            var recipes: [Recipe] = []
//            
//            // Check if the file already exists
//            if FileManager.default.fileExists(atPath: fileURL.path) {
//                // Load existing recipes
//                let data = try Data(contentsOf: fileURL)
//                recipes = try JSONDecoder().decode([Recipe].self, from: data)
//            }
//            
//            var newRecipe = self.recipe
//            while recipes.contains(where: { $0.title == newRecipe!.title }) {
//                self.errorMessage = "Recipe name already exists. Please choose a different name."
//                self.showingNamingDialog = true
//            }
//            
//            // Append the new recipe
//            recipes.append(newRecipe!)
//            
//            // Save updated recipes back to file
//            let newData = try encoder.encode(recipes)
//            try newData.write(to: fileURL)
//            
//            print("Recipe appended to \(fileURL)")
//        } catch {
//            print("Error saving recipe: \(error)")
//        }
//    }
//    
//    struct NamingDialog: View {
//        @Binding var recipeName: String
//        var onSave: () -> Void
//
//        var body: some View {
//            VStack {
//                Text("Enter Recipe Name")
//                TextField("Recipe Name", text: $recipeName)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                Button("Save") {
//                    onSave()
//                }
//            }
//            .padding()
//        }
//    }
//}
