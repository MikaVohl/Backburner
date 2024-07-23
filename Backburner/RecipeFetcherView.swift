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
//    @State private var recipeName: String = ""
//    @State private var showingAlert: Bool = false
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
//            .alert("Rename Recipe", isPresented: $showingAlert) {
//                TextField("Recipe name already exists. Please enter a new name:", text: $recipeName)
//                Button("Save", action: {
//                    showingAlert = false
//                    checkAndSaveRecipe()
//                })
//                Button("Cancel", action: {
//                    showingAlert = false
//                })
//            }
        }
    }
    
    func fetchRecipe() {
        
        guard let urlWithQuery = URL(string: "http://10.0.0.50:5000/scrape?url=\(String(describing: url))") else {
            errorMessage = "Invalid query URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: urlWithQuery)
        request.httpMethod = "GET"
        
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
//                    self.recipeName = self.recipe?.title ?? ""
                    // Directly attempt to save the recipe
                    checkAndSaveRecipe()
                } catch {
                    print(error)
                    errorMessage = "Error decoding response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func checkAndSaveRecipe() {
        guard var newRecipe = self.recipe else { return }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent("recipes.json")
        
        var recipes: [Recipe] = []
        
        if let data = try? Data(contentsOf: fileURL),
           let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decodedRecipes
        }
        
        let maxId = recipes
            .filter { $0.id != nil }
            .max(by: { ($0.id ?? 0) < ($1.id ?? 0) })?.id ?? 0
        
        let imageURLString = newRecipe.image
        if let imageURL = URL(string: imageURLString) {
            downloadImage(url: imageURL, filename: String(maxId)) { result in
                switch result {
                case .success(let fileName):
                    print("Image saved as ", fileName)
                    newRecipe.local_image = fileName
                    newRecipe.id = maxId + 1
                    recipes.append(newRecipe)
                    do {
                        let encodedData = try JSONEncoder().encode(recipes)
                        try encodedData.write(to: fileURL)
                        self.successMessage = "Successfully saved recipe"
                        self.errorMessage = ""
                    } catch {
                        self.errorMessage = "Failed to save recipe"
                        print("Failed to save recipe:", error)
                    }
                case .failure(let error):
                    print("Failed to download image:", error)
                    self.errorMessage = "Failed to save recipe"
                }
            }
        }
        
//        if recipes.contains(where: { $0.title == self.recipeName }) { // check if user-chosen name matches any existing names
//            var uniqueNameFound = false
//            var nameCounter = 1
//            let originalName = self.recipeName
//
//            while !uniqueNameFound {
//                if recipes.contains(where: { $0.title == self.recipeName }) {
//                    // If the name exists, append a counter to the name and check again
//                    self.recipeName = "\(originalName) (\(nameCounter))"
//                    nameCounter += 1
//                } else {
//                    // If the name doesn't exist, exit the loop
//                    uniqueNameFound = true
//                }
//            }
//            
//            
//            self.successMessage = ""
//            self.errorMessage = "Name already exists"
//            self.showingAlert = true
//            return
//        }
//        else{ // no naming conflicts
//            let imageURLString = newRecipe.image
//            if let imageURL = URL(string: imageURLString) {
//                downloadImage(url: imageURL) { result in
//                    switch result {
//                    case .success(let fileName):
//                        print("Image saved as ", fileName)
//                        newRecipe.local_image = fileName
//                    case .failure(let error):
//                        print("Failed to download image:", error)
//                        self.successMessage = "Successfully saved recipe"
//                        self.errorMessage = ""
//                        saveRecipe(newRecipe: newRecipe, recipes: recipes, fileURL: fileURL)
//                    }
//                }
//            }
//        }
    }
    
//    func checkAndSaveRecipe() {
//        guard var newRecipe = self.recipe else { return }
//        
//        let imageURLString = newRecipe.image
//        if let imageURL = URL(string: imageURLString) {
//            downloadImage(url: imageURL) { result in
//                switch result {
//                case .success(let fileName):
//                    print("Image saved as ", fileName)
//                    newRecipe.local_image = fileName
//                case .failure(let error):
//                    print("Failed to download image:", error)
//                }
//                let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//                let fileURL = documentDirectory.appendingPathComponent("recipes.json")
//                
//                var recipes: [Recipe] = []
//                
//                if let data = try? Data(contentsOf: fileURL),
//                   let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: data) {
//                    recipes = decodedRecipes
//                }
//                repeat {
//                    if recipes.contains(where: { $0.title == newRecipe.title }) {
//                        var count = 1
//                        var uniqueTitle = "\(newRecipe.title) (\(count))"
//                        while recipes.contains(where: { $0.title == uniqueTitle }) {
//                            count += 1 // Increment count if the title is not unique
//                            uniqueTitle = "\(newRecipe.title) (\(count))" // Update uniqueTitle with the new count
//                        }
//                        self.recipeName = uniqueTitle
//                        self.showingAlert = true
//                        print("showing alert")
//                    } else {
//                        // If no conflict, save the recipe
//                        recipes.append(newRecipe)
//                        if let encodedData = try? JSONEncoder().encode(recipes) {
//                            try? encodedData.write(to: fileURL)
//                        }
//                        self.successMessage = "Successfully saved recipe"
//                        self.errorMessage = ""
//                        self.showingAlert = false
//                        print("hiding alert")
//                    }
//                } while recipes.contains(where: { $0.title == self.recipeName })
//            }
//        }
//    }
//    func saveRecipe(newRecipe: Recipe, recipes: [Recipe], fileURL: URL) {
//        var recipesList = recipes
//        recipesList.append(newRecipe)
//        if let encodedData = try? JSONEncoder().encode(recipesList) {
//            try? encodedData.write(to: fileURL)
//        }
//        
//        self.successMessage = "Successfully saved recipe"
//        self.errorMessage = ""
//        self.showingAlert = false
//    }
    
    func downloadImage(url: URL, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        let fileManager = FileManager.default
//        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        let imagesDirectory = appSupportDirectory.appendingPathComponent("images")
//        let documentsDirectory = filemanager.urls(
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")

        // Create the images directory if it doesn't exist
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                completion(.failure(error))
                return
            }
        }

        URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location = location else {
                completion(.failure(error ?? NSError(domain: "DownloadError", code: 0, userInfo: nil)))
                return
            }
            var file_name = filename
//            var filename = response?.suggestedFilename ?? url.lastPathComponent
            var destinationURL = imagesDirectory.appendingPathComponent(file_name)

            // Generate a unique filename if it already exists
            var fileIndex = 1
            while fileManager.fileExists(atPath: destinationURL.path) {
                let fileExtension = (file_name as NSString).pathExtension
                let fileNameWithoutExtension = (file_name as NSString).deletingPathExtension
                file_name = "\(fileNameWithoutExtension)_\(fileIndex).\(fileExtension)"
                destinationURL = imagesDirectory.appendingPathComponent(file_name)
                fileIndex += 1
            }

            // Move the downloaded file to the images directory
            do {
                try fileManager.moveItem(at: location, to: destinationURL)
                completion(.success(file_name))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

}
