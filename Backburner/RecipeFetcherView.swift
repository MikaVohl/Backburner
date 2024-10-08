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
                        .foregroundStyle(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .padding()
                }
                
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
            }
            .padding()
        }
    }
    
    func fetchRecipe() {
        
        guard let urlWithQuery = URL(string: "https://recipescraperapi.onrender.com/scrape?url=\(String(describing: url))") else {
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
                    newRecipe.tags = newRecipe.keywords ?? []
                    if let cuisine = newRecipe.cuisine, !newRecipe.tags!.contains(cuisine) {
                        newRecipe.tags!.append(cuisine)
                    }
                    if let category = newRecipe.category, !newRecipe.tags!.contains(category) {
                        newRecipe.tags!.append(category)
                    }
                    if let cooking_method = newRecipe.cooking_method, !newRecipe.tags!.contains(cooking_method) {
                        newRecipe.tags!.append(cooking_method)
                    }
                    recipes.append(newRecipe)
                    do {
                        let encodedData = try JSONEncoder().encode(recipes)
                        try encodedData.write(to: fileURL)
                        print("Successfully saved recipe to \(fileURL)")
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
    }
        
    func downloadImage(url: URL, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        let fileManager = FileManager.default
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
