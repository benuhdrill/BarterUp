//
//  SearchView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SkillPost] = []
    @State private var selectedCategory = "All"
    @State private var isGridView = false
    @Binding var selectedTab: Int
    private let db = Firestore.firestore()
    private let skillsManager = SkillsManager.shared
    
    // Get categories from SkillsManager
    private var categories: [String] {
        ["All"] + skillsManager.getAllCategories()
    }
    
    var filteredResults: [SkillPost] {
        if selectedCategory == "All" {
            return searchResults
        }
        return searchResults.filter { post in
            post.offeringSkill.contains(selectedCategory) ||
            post.seekingSkill.contains(selectedCategory)
        }
    }
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    init(selectedTab: Binding<Int>) {
        _selectedTab = selectedTab
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
                            .onChange(of: searchText) { newValue in
                                searchSkills(query: newValue)
                            }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // View Toggle Button
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
                
                // Search Results
                ScrollView {
                    if isGridView {
                        // Grid View
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredResults) { post in
                                GridSkillPostView(post: post)
                            }
                        }
                        .padding()
                    } else {
                        // List View
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
                
                if filteredResults.isEmpty && !searchText.isEmpty {
                    EmptySearchView(searchText: searchText)
                }
            }
            .navigationTitle("Search Skills")
        }
    }
    
    private func searchSkills(query: String) {
        guard !query.isEmpty else {
            searchResults.removeAll()
            return
        }
        
        print("Searching for: \(query)") // Debug print
        
        db.collection("posts")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching skills: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found") // Debug print
                    searchResults.removeAll()
                    return
                }
                
                print("Found \(documents.count) documents") // Debug print
                
                searchResults = documents.compactMap { document -> SkillPost? in
                    do {
                        let post = try document.data(as: SkillPost.self)
                        print("Document data: \(document.data())") // Debug print
                        return post
                    } catch {
                        print("Error decoding document: \(error)") // Debug print
                        return nil
                    }
                }.filter { post in
                    let offeringMatch = post.offeringSkill.lowercased().contains(query.lowercased())
                    let seekingMatch = post.seekingSkill.lowercased().contains(query.lowercased())
                    print("Post offering: \(post.offeringSkill), seeking: \(post.seekingSkill), matches: \(offeringMatch || seekingMatch)") // Debug print
                    return offeringMatch || seekingMatch
                }
                
                print("Final results count: \(searchResults.count)") // Debug print
            }
    }
}

// Add this CategoryButton view
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

// Add this new view for grid items
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

// Add this view for empty search results
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
