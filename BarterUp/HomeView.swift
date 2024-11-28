//
//  HomeView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/24/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

// Add this struct for the skill post model
struct SkillPost: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let timePosted: Date
    let offeringSkill: String
    let seekingSkill: String
    let details: String
    var isStarred: Bool
    var isLiked: Bool
    var likesCount: Int
    
    init(id: String = UUID().uuidString,
         userId: String = Auth.auth().currentUser?.uid ?? "",
         userName: String,
         timePosted: Date,
         offeringSkill: String,
         seekingSkill: String,
         details: String,
         isStarred: Bool = false,
         isLiked: Bool = false,
         likesCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.timePosted = timePosted
        self.offeringSkill = offeringSkill
        self.seekingSkill = seekingSkill
        self.details = details
        self.isStarred = isStarred
        self.isLiked = isLiked
        self.likesCount = likesCount
    }
}

struct RefreshControl: View {
    var coordinateSpace: CoordinateSpace
    var onRefresh: () -> Void
    @State private var refresh: Bool = false
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            if (geo.frame(in: coordinateSpace).midY > 50) {
                Spacer()
                    .onAppear {
                        if !refresh {
                            refresh = true
                            onRefresh()
                        }
                    }
            } else if (geo.frame(in: coordinateSpace).maxY < 1) {
                Spacer()
                    .onAppear {
                        refresh = false
                    }
            }
            ZStack(alignment: .center) {
                if refresh {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
            .frame(width: geo.size.width)
            .offset(y: -offset)
        }
        .padding(.top, -50)
    }
}

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showNewPostSheet = false
    @State private var selectedTab: Int = 0
    @State private var skillPosts: [SkillPost] = []
    @State private var unreadCount: Int = 0
    
    private let db = Firestore.firestore()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            VStack(spacing: 0) {
                HStack {
                    Button(action: signOut) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Text("BarterUp")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { showNewPostSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                ScrollView {
                    RefreshControl(coordinateSpace: .named("refresh")) {
                        fetchPosts()
                    }
                    LazyVStack(spacing: 0) {
                        ForEach(skillPosts) { post in
                            SkillPostView(
                                post: post,
                                selectedTab: $selectedTab,
                                onUpdate: { updatedPost in
                                    if let index = skillPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                                        skillPosts[index] = updatedPost
                                    }
                                }
                            )
                            Divider()
                        }
                    }
                }
                .coordinateSpace(name: "refresh")
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Search Tab
            SearchView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
            
            // Favorites Tab
            FavoritesView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
                .tag(2)
            
            // Messages Tab
            MessagesView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Messages")
                }
                .badge(unreadCount)
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .sheet(isPresented: $showNewPostSheet) {
            NewSkillPostView(onPost: { offering, seeking, details in
                addNewPost(offering: offering, seeking: seeking, details: details)
            })
        }
        .onAppear {
            fetchPosts()
            fetchUnreadCount()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    private func fetchPosts() {
        db.collection("posts")
            .order(by: "timePosted", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                skillPosts = documents.compactMap { document -> SkillPost? in
                    try? document.data(as: SkillPost.self)
                }
            }
    }
    
    private func fetchUnreadCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("conversations")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching unread count: \(error)")
                    return
                }
                
                let count = querySnapshot?.documents.reduce(0) { sum, document in
                    sum + (document.data()["unreadCount"] as? Int ?? 0)
                } ?? 0
                
                DispatchQueue.main.async {
                    self.unreadCount = count
                }
            }
    }
    
    private func addNewPost(offering: String, seeking: String, details: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No current user")
            return
        }
        
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            guard let userData = document?.data(),
                  let username = userData["username"] as? String else {
                print("Could not get username")
                return
            }
            
            let newPost = SkillPost(
                userName: username,
                timePosted: Date(),
                offeringSkill: offering,
                seekingSkill: seeking,
                details: details
            )
            
            do {
                try self.db.collection("posts").document(newPost.id).setData(from: newPost)
                print("Post saved successfully with username: \(username)")
            } catch {
                print("Error adding post: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleFavorite(post: SkillPost) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let favoriteRef = db.collection("users")
            .document(userId)
            .collection("favorites")
            .document(post.id)
        
        if post.isStarred {
            // Remove from favorites
            favoriteRef.delete { error in
                if let error = error {
                    print("Error removing favorite: \(error)")
                }
            }
        } else {
            // Add to favorites
            do {
                try favoriteRef.setData(from: post)
            } catch {
                print("Error adding favorite: \(error)")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
