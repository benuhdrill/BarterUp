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
    let userName: String
    let timePosted: Date
    let offeringSkill: String
    let seekingSkill: String
    let details: String
    var isStarred: Bool
    var isLiked: Bool
    
    // Add initializer for Firestore
    init(id: String = UUID().uuidString,
         userName: String,
         timePosted: Date,
         offeringSkill: String,
         seekingSkill: String,
         details: String,
         isStarred: Bool = false,
         isLiked: Bool = false) {
        self.id = id
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
    @State private var skillPosts: [SkillPost] = [] // Add this state
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
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
                        // Refresh your content here
                    }
                    LazyVStack(spacing: 0) {
                        ForEach(skillPosts) { post in
                            SkillPostView(post: post, onUpdate: { updatedPost in
                                if let index = skillPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                                    skillPosts[index] = updatedPost
                                }
                            })
                            Divider()
                        }
                    }
                }
                .coordinateSpace(name: "refresh")
                
                // Modified Bottom Navigation Bar (removed notifications)
                HStack {
                    TabBarButton(image: "house.fill", text: "Home", isActive: selectedTab == 0)
                        .onTapGesture { selectedTab = 0 }
                    TabBarButton(image: "magnifyingglass", text: "Explore", isActive: selectedTab == 1)
                        .onTapGesture { selectedTab = 1 }
                    TabBarButton(image: "star.fill", text: "Favorites", isActive: selectedTab == 2)
                        .onTapGesture { selectedTab = 2 }
                    TabBarButton(image: "envelope.fill", text: "Messages", isActive: selectedTab == 3)
                        .onTapGesture { selectedTab = 3 }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .overlay(
                    Divider()
                        .padding(.horizontal, -16)
                        .opacity(0.3)
                    , alignment: .top
                )
            }
        }
        .sheet(isPresented: $showNewPostSheet) {
            NewSkillPostView(onPost: { offering, seeking, details in
                addNewPost(offering: offering, seeking: seeking, details: details)
            })
        }
        .onAppear {
            fetchPosts()  // This will load posts when the view appears
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
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let newPost = SkillPost(
            userName: currentUser.displayName ?? "Anonymous",
            timePosted: Date(),
            offeringSkill: offering,
            seekingSkill: seeking,
            details: details
        )
        
        do {
            // Save to Firestore
            try db.collection("posts").document(newPost.id).setData(from: newPost)
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
    let onUpdate: (SkillPost) -> Void
    @State private var isPressed: Bool
    @State private var isStarred: Bool
    
    init(post: SkillPost, onUpdate: @escaping (SkillPost) -> Void) {
        self.post = post
        self.onUpdate = onUpdate
        _isPressed = State(initialValue: post.isLiked)
        _isStarred = State(initialValue: post.isStarred)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                Button(action: {}) {
                    Label("128", systemImage: "message")
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
}

// New Skill Post View
struct NewSkillPostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var postText = ""
    @State private var offeringSkill = ""
    @State private var seekingSkill = ""
    let onPost: (String, String, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Updated TextField styles
                TextField("What skills are you offering?", text: $offeringSkill)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextField("What skills are you seeking?", text: $seekingSkill)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                TextEditor(text: $postText)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            if postText.isEmpty {
                                Text("Add more details about your exchange...")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                        }
                        , alignment: .topLeading
                    )
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Skill Exchange")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        onPost(offeringSkill, seekingSkill, postText)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
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

