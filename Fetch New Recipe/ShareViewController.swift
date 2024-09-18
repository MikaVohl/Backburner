//
//  ShareViewController.swift
//  Fetch New Recipe
//
//  Created by Mika Vohl on 2024-07-28.
//

import UIKit
import Social

struct Recipe: Codable, Hashable {
    var id: Int?
    var tags: [String]?
    var local_image: String?
    
    // From scraper
    var host: String
    var canonical_url: String?
    var title: String
    var category: String?
    var total_time: Int
    var cook_time: Int?
    var prep_time: Int?
    var cooking_method: String?
    var yields: String
    var image: String
    var nutrients: [String: String]?
    var keywords: [String]?
    var language: String?
    var ingredients: [String]
    var ingredient_groups: [IngredientGroup]
    var instructions: String
    var instructions_list: [String]
    var ratings: Double?
    var ratings_count: Int?
    var author: String?
    var cuisine: String?
    var description: String?
    var reviews: [String]?
    var equipment: [String]?
    var dietary_restrictions: [String]?
    var site_name: String?
}

struct IngredientGroup: Codable, Hashable {
    var ingredients: [String]
    var purpose: String?
}


class ShareViewController: SLComposeServiceViewController {
//    @State private var url: String = ""
//    @State private var isLoading: Bool = false
//    @State private var errorMessage: String?
//    @State private var successMessage: String?
//    @State private var recipe: Recipe?
    var real_url: URL?
    var recipe: Recipe?
    var isLoading = true
    var errorMessage = ""
    var successMessage = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change the "Post" button to say "Fetch"
        if let button = navigationController?.navigationBar.topItem?.rightBarButtonItem {
            button.title = "Fetch"
        }
        textView.isUserInteractionEnabled = false
//        textView.textColor = UIColor(white: 0.5, alpha: 1)
        textView.tintColor = UIColor.clear // TODO hack to disable cursor
        getUrl { (url: URL?) in
            if let url = url {
                DispatchQueue.main.async {
                    // TODO this is also hacky
                    self.textView.text = "\(url)"
                    self.real_url = url
                }
            }
        }
    }
    
    func getUrl(callback: @escaping ((URL?) -> ())) {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = item.attachments?.first as? NSItemProvider,
            itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                if let shareURL = url as? URL {
                    callback(shareURL)
                }
            }
        }
        callback(nil)
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        fetchRecipe()
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    func fetchRecipe() {
        guard let unwrappedUrl = real_url else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
            
        let queryUrlString = "https://recipescraperapi.onrender.com/scrape?url=\(unwrappedUrl.absoluteString)"
        guard let urlWithQuery = URL(string: queryUrlString) else {
            self.errorMessage = "Invalid query URL"
            self.isLoading = false
            return
        }

        print(urlWithQuery)
        var request = URLRequest(url: urlWithQuery)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data else {
                    self.errorMessage = error?.localizedDescription ?? "Unknown error"
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(Recipe.self, from: data)
                    self.recipe = decodedResponse
                    self.checkAndSaveRecipe()
                } catch {
                    print(error)
                    self.errorMessage = "Error decoding response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func checkAndSaveRecipe() {
        guard var newRecipe = self.recipe else { return }
        
        let fileManager = FileManager.default
        let appGroupID = "com.mikavohl.backburner" // Replace with your App Group ID
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentDirectory.appendingPathComponent("recipes.json")
        
        print("Document directory: \(documentDirectory)")
        print("Recipes file URL: \(fileURL)")
        
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
