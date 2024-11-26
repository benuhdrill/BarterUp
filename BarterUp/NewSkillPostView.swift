//
//  NewSkillPostView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NewSkillPostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var postText = ""
    @State private var selectedOfferingCategory = ""
    @State private var selectedSeekingCategory = ""
    @State private var offeringSkill = ""
    @State private var seekingSkill = ""
    @State private var isCustomOfferingSkill = false
    @State private var isCustomSeekingSkill = false
    @State private var customOfferingSkill = ""
    @State private var customSeekingSkill = ""
    
    let skillsManager = SkillsManager.shared
    let onPost: (String, String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                // Offering Section
                Section(header: Text("What skill can you offer?")) {
                    Picker("Category", selection: $selectedOfferingCategory) {
                        Text("Select Category").tag("")
                        ForEach(skillsManager.getAllCategories(), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    if !selectedOfferingCategory.isEmpty {
                        Toggle("Custom Skill", isOn: $isCustomOfferingSkill)
                        
                        if isCustomOfferingSkill {
                            TextField("Enter your skill", text: $customOfferingSkill)
                                .autocapitalization(.words)
                        } else {
                            Picker("Skill", selection: $offeringSkill) {
                                Text("Select Skill").tag("")
                                ForEach(skillsManager.getSkills(for: selectedOfferingCategory), id: \.self) { skill in
                                    Text(skill).tag(skill)
                                }
                            }
                        }
                    }
                }
                
                // Seeking Section
                Section(header: Text("What skill are you looking for?")) {
                    Picker("Category", selection: $selectedSeekingCategory) {
                        Text("Select Category").tag("")
                        ForEach(skillsManager.getAllCategories(), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    if !selectedSeekingCategory.isEmpty {
                        Toggle("Custom Skill", isOn: $isCustomSeekingSkill)
                        
                        if isCustomSeekingSkill {
                            TextField("Enter desired skill", text: $customSeekingSkill)
                                .autocapitalization(.words)
                        } else {
                            Picker("Skill", selection: $seekingSkill) {
                                Text("Select Skill").tag("")
                                ForEach(skillsManager.getSkills(for: selectedSeekingCategory), id: \.self) { skill in
                                    Text(skill).tag(skill)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Additional Details")) {
                    TextEditor(text: $postText)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Skill Exchange")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        let finalOfferingSkill = isCustomOfferingSkill ? customOfferingSkill : offeringSkill
                        let finalSeekingSkill = isCustomSeekingSkill ? customSeekingSkill : seekingSkill
                        let formattedOffering = "\(selectedOfferingCategory): \(finalOfferingSkill)"
                        let formattedSeeking = "\(selectedSeekingCategory): \(finalSeekingSkill)"
                        onPost(formattedOffering, formattedSeeking, postText)
                        dismiss()
                    }
                    .disabled(isPostButtonDisabled)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private var isPostButtonDisabled: Bool {
        selectedOfferingCategory.isEmpty || selectedSeekingCategory.isEmpty ||
        (isCustomOfferingSkill ? customOfferingSkill.isEmpty : offeringSkill.isEmpty) ||
        (isCustomSeekingSkill ? customSeekingSkill.isEmpty : seekingSkill.isEmpty)
    }
}
