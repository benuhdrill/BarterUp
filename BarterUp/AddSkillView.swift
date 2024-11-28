//
//  AddSkillView.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI

struct AddSkillView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newSkill = ""
    
    enum SkillType {
        case offering, seeking
    }
    
    let skillType: SkillType
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Enter skill", text: $newSkill)
            }
            .navigationTitle(skillType == .offering ? "Add Skill to Offer" : "Add Skill to Learn")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    if !newSkill.isEmpty {
                        onAdd(newSkill)
                        dismiss()
                    }
                }
                .disabled(newSkill.isEmpty)
            )
        }
    }
}
