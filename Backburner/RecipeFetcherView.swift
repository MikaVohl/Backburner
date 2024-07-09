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
    @State private var successMessage: String?
    @State private var recipe: Recipe?
//    @State private var showingNamingDialog: Bool = false
    @State private var recipeName: String = ""
    @State private var showingAlert: Bool = false
    @State private var alertText: String = ""
    
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
                
                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding()
                }
                
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
            }
            .padding()
//            .alert(isPresented: $showingAlert) {
//                Alert(
//                    title: Text("Rename Recipe"),
//                    message: TextField("Recipe name already exists. Please enter a new name:", text: $recipeName),
//                    primaryButton: .default(Text("Save"), action: {
//                        // Save action
//                        self.recipe?.title = self.alertText
//                        checkAndSaveRecipe()
//                    }),
//                    secondaryButton: .cancel()
//                )
//            }
            .alert("Rename Recipe", isPresented: $showingAlert) {
                TextField("Recipe name already exists. Please enter a new name:", text: $recipeName)
                Button("Save", action: {
                    self.recipe?.title = self.recipeName
                    checkAndSaveRecipe()
                })
                Button("Cancel", action: {
                    showingAlert = false
                })
            }//            .sheet(isPresented: $showingNamingDialog) {
//                NamingDialog(recipeName: $recipeName) {
//                    // Update the recipe title with the new name
//                    self.recipe?.title = self.recipeName
//                    // Attempt to save again
//                    checkAndSaveRecipe()
//                }
//            }
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
    
    func presentRenameAlert() {
        self.showingAlert = true
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
        repeat {
            if recipes.contains(where: { $0.title == newRecipe.title }) {
                var count = 1
                var uniqueTitle = "\(newRecipe.title) (\(count))"
                while recipes.contains(where: { $0.title == uniqueTitle }) {
                    count += 1 // Increment count if the title is not unique
                    uniqueTitle = "\(newRecipe.title) (\(count))" // Update uniqueTitle with the new count
                }
                self.recipeName = uniqueTitle
//                self.showingNamingDialog = true
                presentRenameAlert()
            } else {
                // If no conflict, save the recipe
                recipes.append(newRecipe)
                if let encodedData = try? JSONEncoder().encode(recipes) {
                    try? encodedData.write(to: fileURL)
                }
                self.successMessage = "Successfully saved recipe"
                self.errorMessage = ""
//                self.showingNamingDialog = false
            }
        } while recipes.contains(where: { $0.title == self.recipeName })
    }
//    
//    struct NamingDialog: View {
//        @Binding var recipeName: String
//        var onSave: () -> Void
//        
//        var body: some View {
//            VStack {
//                Text("Recipe name already exists. Please enter a new name:")
//                TextField("New Recipe Name", text: $recipeName)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                Button("Save") {
//                    onSave()
//                }
//                .padding()
//            }
//            .padding()
//        }
//    }
}
