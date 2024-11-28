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
    @State private var selectedFilter: SearchFilter = .all
    @State private var searchResults: [SkillPost] = []
    private let db = Firestore.firestore()
    
    enum SearchFilter {
        case all, offering, seeking
    }
    
    var filteredResults: [SkillPost] {
        if searchText.isEmpty {
            return searchResults
        }
        
        return searchResults.filter { post in
            switch selectedFilter {
            case .all:
                return post.offeringSkill.localizedCaseInsensitiveContains(searchText) ||
                       post.seekingSkill.localizedCaseInsensitiveContains(searchText)
            case .offering:
                return post.offeringSkill.localizedCaseInsensitiveContains(searchText)
            case .seeking:
                return post.seekingSkill.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search skills...", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter Buttons
                HStack {
                    FilterButton(title: "All", isSelected: selectedFilter == .all) {
                        selectedFilter = .all
                    }
                    FilterButton(title: "Offering", isSelected: selectedFilter == .offering) {
                        selectedFilter = .offering
                    }
                    FilterButton(title: "Seeking", isSelected: selectedFilter == .seeking) {
                        selectedFilter = .seeking
                    }
                }
                .padding(.horizontal)
                
                // Results List
                if filteredResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .font(.title2)
                        Text("Try adjusting your search")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
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
            .navigationTitle("Search")
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

