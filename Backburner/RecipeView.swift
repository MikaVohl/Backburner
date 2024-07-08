////
////  RecipeView.swift
////  Backburner
////
////  Created by Mika Vohl on 2024-07-01.
////
//
//import SwiftUI
//
//struct RecipeView: View {
//    @State private var recipe: Recipe?
//    @State private var url: String = "" // URL input field
//    @State private var isLoading: Bool = false
//    @State private var errorMessage: String?
//
//    var body: some View {
//        VStack {
//            TextField("Enter Recipe URL", text: $url)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//
//            Button(action: {
//                print(listSavedRecipeTitles())
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
//
//            if let recipe = recipe {
//                ScrollView {
//                    HStack {
//                        VStack(alignment: .leading, spacing: 10) {
//                            Text(recipe.title)
//                                .font(.largeTitle)
//                                .padding()
//
//                            Text("Ingredients")
//                                .font(.headline)
//                                .padding(.top)
//                            ForEach(recipe.ingredients, id: \.self) { ingredient in
//                                Text(ingredient)
//                                    .padding(.bottom, 2)
//                            }
//
//                            Text("Instructions")
//                                .font(.headline)
//                                .padding(.top)
//                            Text(recipe.instructions)
//                                .padding()
//                        }
//                        .padding()
//
//                        AsyncImage(url: URL(string: recipe.image)) { image in
//                                image.resizable()
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            .frame(width: 300, height: 300)
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//
//    func fetchRecipe() {
//        guard let endpointUrl = URL(string: "http://10.0.0.182:5000/scrape") else {
//            print("Invalid URL")
//            return
//        }
//
//        let parameters: [String : Any] = ["url": url] // Adjust parameters as needed
//        var request = URLRequest(url: endpointUrl)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
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
//                    saveRecipeToStorage(recipe: decodedResponse)
//                } catch {
//                    errorMessage = "Error decoding response: \(error.localizedDescription)"
//                }
//            }
//        }.resume()
//    }
//
//    func saveRecipeToStorage(recipe: Recipe) {
//        do {
//            let encoder = JSONEncoder()
//            let data = try encoder.encode(recipe)
//            if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                var fileName = recipe.title.replacingOccurrences(of: " ", with: "_") + ".json"
//                var fileURL = documentDirectory.appendingPathComponent(fileName)
//
//                // Check if the file exists and append a number to make a unique file name
//                var fileCounter = 1
//                while FileManager.default.fileExists(atPath: fileURL.path) {
//                    fileName = recipe.title.replacingOccurrences(of: " ", with: "_") + "_\(fileCounter).json"
//                    fileURL = documentDirectory.appendingPathComponent(fileName)
//                    fileCounter += 1
//                }
//
//                try data.write(to: fileURL)
//                print("Recipe saved to \(fileURL)")
//            }
//        } catch {
//            print("Error saving recipe: \(error)")
//        }
//    }
//
//    func listSavedRecipeTitles() -> [String] {
//        var titles = [String]()
//
//        // Get the documents directory URL
//        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            print("Documents directory not found")
//            return titles
//        }
//
//        do {
//            // List all files in the documents directory
//            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
//
//            // Filter for JSON files if your recipes are saved with a .json extension
//            let recipeFiles = fileURLs.filter { $0.pathExtension == "json" }
//
//            for fileURL in recipeFiles {
//                // Decode each recipe file
//                if let data = try? Data(contentsOf: fileURL) {
//                    if let recipe = try? JSONDecoder().decode(Recipe.self, from: data) {
//                        // Add the title to the titles array
//                        titles.append(recipe.title)
//                    }
//                }
//            }
//        } catch {
//            print("Error listing recipe files: \(error)")
//        }
//
//        return titles
//    }
//}
//
//struct RecipeView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeView()
//    }
//}
