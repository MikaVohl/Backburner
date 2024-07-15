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
            .alert("Rename Recipe", isPresented: $showingAlert) {
                TextField("Recipe name already exists. Please enter a new name:", text: $recipeName)
                Button("Save", action: {
                    self.recipe?.title = self.recipeName
                    checkAndSaveRecipe()
                })
                Button("Cancel", action: {
                    showingAlert = false
                })
            }
        }
    }
    
    func fetchRecipe() {
        guard let endpointUrl = URL(string: "http://10.0.0.51:5000/scrape") else {
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
        guard var newRecipe = self.recipe else { return }
        
        let imageURLString = newRecipe.image
        if let imageURL = URL(string: imageURLString) {
            downloadImage(url: imageURL) { result in
                switch result {
                case .success(let fileName):
                    print("Image saved as ", fileName)
                    newRecipe.local_image = fileName
                case .failure(let error):
                    print("Failed to download image:", error)
                }
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
                        presentRenameAlert()
                    } else {
                        // If no conflict, save the recipe
                        recipes.append(newRecipe)
                        if let encodedData = try? JSONEncoder().encode(recipes) {
                            try? encodedData.write(to: fileURL)
                        }
                        self.successMessage = "Successfully saved recipe"
                        self.errorMessage = ""
                    }
                } while recipes.contains(where: { $0.title == self.recipeName })
            }
        }
    }
    
//    func downloadImage(from url: URL, completion: @escaping (URL?) -> Void) {
//        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
//            guard let location = location, error == nil else {
//                completion(nil)
//                return
//            }
//
//            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            let fileName = url.lastPathComponent
//            let destinationURL = documentDirectory.appendingPathComponent(fileName)
//
//            do {
//                try FileManager.default.moveItem(at: location, to: destinationURL)
//                completion(destinationURL)
//            } catch {
//                completion(nil)
//            }
//        }
//        task.resume()
//}
        
//    func downloadImage(url: URL) {
//        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        URLSession.shared.downloadTask(with: url) { location, response, error in
//            guard let location = location else {
//                print("download error:", error ?? "")
//                return
//            }
//            // move the downloaded file from the temporary location url to your app documents directory
//            do {
//                try FileManager.default.moveItem(at: location, to: documents.appendingPathComponent(response?.suggestedFilename ?? url.lastPathComponent))
//            } catch {
//                print(error)
//            }
//        }.resume()
//    }
        
    func downloadImage(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
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

            var filename = response?.suggestedFilename ?? url.lastPathComponent
            var destinationURL = imagesDirectory.appendingPathComponent(filename)

            // Generate a unique filename if it already exists
            var fileIndex = 1
            while fileManager.fileExists(atPath: destinationURL.path) {
                let fileExtension = (filename as NSString).pathExtension
                let fileNameWithoutExtension = (filename as NSString).deletingPathExtension
                filename = "\(fileNameWithoutExtension)_\(fileIndex).\(fileExtension)"
                destinationURL = imagesDirectory.appendingPathComponent(filename)
                fileIndex += 1
            }

            // Move the downloaded file to the images directory
            do {
                try fileManager.moveItem(at: location, to: destinationURL)
                print("File moved to:", destinationURL.path)
                completion(.success(filename))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


        
        
        
//        extension URL {
//            func loadImage(_ image: inout UIImage?) {
//                if let data = try? Data(contentsOf: self), let loaded = UIImage(data: data) {
//                    image = loaded
//                } else {
//                    image = nil
//                }
//            }
//            func saveImage(_ image: UIImage?) {
//                if let image = image {
//                    if let data = image.jpegData(compressionQuality: 1.0) {
//                        try? data.write(to: self)
//                    }
//                } else {
//                    try? FileManager.default.removeItem(at: self)
//                }
//            }
//        }
}
