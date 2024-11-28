//
//  AddSkillView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory = ""
    @State private var customSkill = ""
    @State private var isCustomSkill = false
    let skillType: SkillType
    let onAdd: (String) -> Void
    
    private let skillsManager = SkillsManager.shared
    
    enum SkillType {
        case offering, seeking
        
        var title: String {
            switch self {
            case .offering: return "Add Skill to Offer"
            case .seeking: return "Add Skill to Learn"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategory) {
                        Text("Select Category").tag("")
                        ForEach(skillsManager.getAllCategories(), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                if !selectedCategory.isEmpty {
                    Section {
                        Toggle("Custom Skill", isOn: $isCustomSkill)
                        
                        if isCustomSkill {
                            TextField("Enter skill name", text: $customSkill)
                                .autocapitalization(.words)
                        } else {
                            Picker("Select Skill", selection: $customSkill) {
                                Text("Select Skill").tag("")
                                ForEach(skillsManager.getSkills(for: selectedCategory), id: \.self) { skill in
                                    Text(skill).tag(skill)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(skillType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let skillToAdd = "\(selectedCategory): \(customSkill)"
                        onAdd(skillToAdd)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !selectedCategory.isEmpty && !customSkill.isEmpty
    }
}

struct AddSkillView_Previews: PreviewProvider {
    static var previews: some View {
        AddSkillView(skillType: .offering) { _ in }
    }
}
