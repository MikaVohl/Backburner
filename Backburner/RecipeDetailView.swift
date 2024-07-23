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
                
                HStack {
                    RatingStarsView(rating: recipe.ratings ?? 0.0).fixedSize(horizontal: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, vertical: false)
                    Spacer()
                    if let url = recipe.canonical_url, let origin_link = URL(string: url){
                        if recipe.host.count < 20 {
                            Link(recipe.host, destination: origin_link)
                        } else {
                            Link("Recipe Site", destination: origin_link)
                        }
                    }
                    Spacer()
                }
                
                Text("Yields: ").bold() + Text("\(recipe.yields)")
                let total_time = recipe.total_time
                let hours = total_time / 60
                let minutes = total_time % 60
                HStack {
                    Text("Total Time:").bold()
                    if hours > 0 && minutes > 0 {
                        Text("\(hours) hours and \(minutes) minutes")
                    }else if hours > 0 {
                        Text("\(hours) hours")
                    }else if minutes > 0 {
                        Text("\(minutes) minutes")
                    }
                }
                HStack {
                    if let prep_time = recipe.prep_time, let cook_time = recipe.cook_time {
                        let prepHours = prep_time / 60
                        let prepMinutes = prep_time % 60
                        let cookHours = cook_time / 60
                        let cookMinutes = cook_time % 60
                        
                        Text("Prep Time:").bold()
                        if prepHours > 0 && prepMinutes > 0 {
                            Text("\(prepHours)h and \(prepMinutes) min")
                        } else if prepHours > 0 {
                            Text("\(prepHours)h")
                        } else {
                            Text("\(prepMinutes) min")
                        }
                        
                        Text("Cook Time:").bold()
                        if cookHours > 0 && cookMinutes > 0 {
                            Text("\(cookHours)h and \(cookMinutes) min")
                        } else if cookHours > 0 {
                            Text("\(cookHours)h")
                        } else {
                            Text("\(cookMinutes) min")
                        }
                    }
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
                if let tags = recipe.tags {
                    Text("Tags:")
                        .font(.headline)
                    ForEach(tags.indices, id: \.self) { index in
                        Tag(tagName: tags[index])
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle(recipe.title, displayMode: .inline)
    }
}

struct RatingStarsView: View {
    var rating: Double // Rating value from 0 to 5
    var maxRating: Int = 5 // Maximum rating value
    
    private func starType(index: Int) -> String {
        let fullStarCount = Int(rating)
        let hasHalfStar = rating - Double(fullStarCount) >= 0.5
        
        if index < fullStarCount {
            return "star.fill" // Full star
        } else if index == fullStarCount && hasHalfStar {
            return "star.lefthalf.fill" // Half star
        } else {
            return "star" // Empty star
        }
    }
    
    var body: some View {
        HStack {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: starType(index: index))
                    .foregroundStyle(.yellow)
            }
            Text("\(rating, specifier: "%.1f")")
                .foregroundStyle(.yellow)
        }
    }
}

struct Tag: View {
    var tagName: String
    
    let colors = [
        Color.red,
        Color.blue,
        Color.green,
        Color.yellow,
        Color.gray,
        Color.orange,
    ]
    
    var body: some View {
        Text(tagName)
            .padding([.top, .bottom], 7)
            .padding([.leading, .trailing], 10)
            .background(colorFromName(name: tagName).overlay(Color.white.opacity(0.5))) // Overlay the color with white to lighten it
            .foregroundColor(.white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(colorFromName(name: tagName), lineWidth: 2)
            )
    }
    
    func colorFromName(name: String) -> Color {
        let hash = abs(name.hashValue) % colors.count // Ensure the index is within the bounds of the colors array
        return colors[hash]
    }
//    func colorFromName(name: String) -> Color {
//        // Hash the name and use the hash to generate a color
//        let hash = name.hashValue
//        let red = Double((hash & 0xFF0000) >> 16) / 255.0
//        let green = Double((hash & 0x00FF00) >> 8) / 255.0
//        let blue = Double(hash & 0x0000FF) / 255.0
//        
//        return Color(red: red, green: green, blue: blue, opacity: 1.0)
//    }
}
