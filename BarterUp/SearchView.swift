//
//  SearchView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SearchView: View {
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isGridView = false
    @State private var searchResults: [SkillPost] = []
    private let db = Firestore.firestore()
    
    // Add this line to declare the skillsManager property
    private let skillsManager = SkillsManager.shared
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var categories: [String] {
        ["All"] + skillsManager.getAllCategories()
    }
    
    var filteredResults: [SkillPost] {
        if searchText.isEmpty && selectedCategory == "All" {
            return searchResults
        }
        
        return searchResults.filter { post in
            let matchesSearch = searchText.isEmpty ||
                post.offeringSkill.localizedCaseInsensitiveContains(searchText) ||
                post.seekingSkill.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == "All" ||
                post.offeringSkill.contains(selectedCategory) ||
                post.seekingSkill.contains(selectedCategory)
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Search Bar and View Toggle
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search for skills...", text: $searchText)
                            .autocapitalization(.none)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: { isGridView.toggle() }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Results Count
                if !searchText.isEmpty {
                    HStack {
                        Text("\(filteredResults.count) results found")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Results List
                if filteredResults.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.title2)
                        Text("Try adjusting your search")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        if isGridView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredResults) { post in
                                    GridSkillPostView(post: post)
                                }
                            }
                            .padding()
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredResults) { post in
                                    SkillPostView(
                                        post: post,
                                        selectedTab: $selectedTab,
                                        onUpdate: { updatedPost in
                                            if let index = searchResults.firstIndex(where: { $0.id == updatedPost.id }) {
                                                searchResults[index] = updatedPost
                                            }
                                        }
                                    )
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Skills")
            .onAppear {
                fetchAllPosts()
            }
        }
    }
    
    private func fetchAllPosts() {
        db.collection("posts")
            .order(by: "timePosted", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                searchResults = querySnapshot?.documents.compactMap { document -> SkillPost? in
                    try? document.data(as: SkillPost.self)
                } ?? []
            }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .blue)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    @State static var selectedTab = 0
    
    static var previews: some View {
        SearchView(selectedTab: $selectedTab)
    }
}

// Add these structs at the bottom of SearchView.swift

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct GridSkillPostView: View {
    let post: SkillPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.gray)
                Text(post.userName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            // Skills
            VStack(alignment: .leading, spacing: 4) {
                SkillTag(text: post.offeringSkill, type: .offering)
                SkillTag(text: post.seekingSkill, type: .seeking)
            }
            
            // Time
            Text(post.timePosted.timeAgo())
                .font(.caption)
                .foregroundColor(.gray)
            
            // Interaction Buttons
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                }
                Button(action: {}) {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No skills found matching '\(searchText)'")
                .foregroundColor(.gray)
        }
        .padding(.top, 100)
    }
}

