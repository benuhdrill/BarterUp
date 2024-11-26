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
    
    // Add initializer for Firestore
    init(id: String = UUID().uuidString,
         userId: String = Auth.auth().currentUser?.uid ?? "",
         userName: String,
         timePosted: Date,
         offeringSkill: String,
         seekingSkill: String,
         details: String,
         isStarred: Bool = false,
         isLiked: Bool = false) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.timePosted = timePosted
        self.offeringSkill = offeringSkill
        self.seekingSkill = seekingSkill
        self.details = details
        self.isStarred = isStarred
        self.isLiked = isLiked
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showNewPostSheet = false
    @State private var selectedTab: Int = 0
    @State private var skillPosts: [SkillPost] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            VStack(spacing: 0) {
                // Modified Navigation Bar
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
                
                // Updated Main Content
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
            Text("Favorites")
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
                .tag(3)
        }
        .sheet(isPresented: $showNewPostSheet) {
            NewSkillPostView(onPost: { offering, seeking, details in
                addNewPost(offering: offering, seeking: seeking, details: details)
            })
        }
        .onAppear {
            fetchPosts()
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // Function to fetch posts
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
    
    // Update addNewPost function
    private func addNewPost(offering: String, seeking: String, details: String) {
        guard let currentUser = Auth.auth().currentUser else { 
            print("No current user")
            return 
        }
        
        print("Creating post with offering: \(offering), seeking: \(seeking)") // Debug print
        
        let newPost = SkillPost(
            userName: currentUser.displayName ?? "Anonymous",
            timePosted: Date(),
            offeringSkill: offering,
            seekingSkill: seeking,
            details: details
        )
        
        do {
            try db.collection("posts").document(newPost.id).setData(from: newPost)
            print("Post saved successfully") // Debug print
        } catch {
            print("Error adding post: \(error.localizedDescription)")
        }
    }
    
    private func updatePost(_ post: SkillPost) {
        do {
            try db.collection("posts").document(post.id).setData(from: post)
        } catch {
            print("Error updating post: \(error.localizedDescription)")
        }
    }
}

// Tab Bar Button
struct TabBarButton: View {
    let image: String
    let text: String
    var isActive: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: image)
                .foregroundColor(isActive ? .blue : .gray)
            Text(text)
                .font(.caption2)
                .foregroundColor(isActive ? .blue : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// Update SkillPostView to use the SkillPost model
struct SkillPostView: View {
    let post: SkillPost
    @Binding var selectedTab: Int
    let onUpdate: (SkillPost) -> Void
    @State private var isPressed = false
    @State private var isStarred = false
    @State private var showChatView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Modified User Info section
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                Text(post.userName)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        isStarred.toggle()
                        var updatedPost = post
                        updatedPost.isStarred = isStarred
                        onUpdate(updatedPost)
                    }
                }) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundColor(isStarred ? .yellow : .gray)
                        .scaleEffect(isStarred ? 1.2 : 1.0)
                }
                Text(post.timePosted.timeAgo())
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.leading, 8)
            }
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Looking to exchange:")
                    .fontWeight(.semibold)
                Text("Offering: \(post.offeringSkill)")
                    .foregroundColor(.blue)
                Text("Seeking: \(post.seekingSkill)")
                    .foregroundColor(.green)
                Text(post.details)
            }
            
            // Interaction Buttons
            HStack(spacing: 32) {
                Button(action: {
                    sendInitialMessage()
                    selectedTab = 3  // Switch to Messages tab
                }) {
                    Label("Message", systemImage: "message")
                        .foregroundColor(.gray)
                }
                Button(action: {}) {
                    Label("45", systemImage: "arrow.2.squarepath")
                        .foregroundColor(.gray)
                }
                Button(action: {
                    withAnimation(.spring()) {
                        isPressed.toggle()
                    }
                }) {
                    Label("234", systemImage: "heart")
                        .foregroundColor(isPressed ? .red : .gray)
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                }
                Button(action: {}) {
                    Label("", systemImage: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
            .padding(.top, 8)
        }
        .padding()
    }
    
    private func sendInitialMessage() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let message = Message(
            senderId: currentUser.uid,
            receiverId: post.userId,
            content: "Hi! I'm interested in exchanging skills!",
            timestamp: Date(),
            senderName: currentUser.displayName ?? "Anonymous"
        )
        
        do {
            try Firestore.firestore().collection("messages").addDocument(from: message)
        } catch {
            print("Error sending initial message: \(error)")
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct SkillTag: View {
    let text: String
    let type: SkillType
    
    enum SkillType {
        case offering, seeking
        
        var color: Color {
            switch self {
            case .offering: return .blue
            case .seeking: return .green
            }
        }
    }
    
    var body: some View {
        Text(text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(type.color.opacity(0.2))
            .foregroundColor(type.color)
            .cornerRadius(16)
            .font(.system(size: 14, weight: .medium))
    }
}

// Add this struct at the bottom of your file
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

// Add this extension for relative time formatting
extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

