//
//  FavoritesView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FavoritesView: View {
    @State private var favoritesPosts: [SkillPost] = []
    @Binding var selectedTab: Int
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                if favoritesPosts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text("No favorites yet")
                            .font(.title2)
                        Text("Star posts to save them here")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(favoritesPosts) { post in
                            SkillPostView(
                                post: post,
                                selectedTab: $selectedTab,
                                onUpdate: { updatedPost in
                                    if let index = favoritesPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                                        favoritesPosts[index] = updatedPost
                                    }
                                }
                            )
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
        }
        .onAppear {
            fetchFavorites()
        }
    }
    
    private func fetchFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("favorites")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("❌ Error fetching favorites: \(error)")
                    return
                }
                
                favoritesPosts = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: SkillPost.self)
                } ?? []
            }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    @State static var selectedTab = 0
    
    static var previews: some View {
        FavoritesView(selectedTab: $selectedTab)
    }
}
