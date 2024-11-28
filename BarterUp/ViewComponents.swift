//
//  ViewComponents.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/28/24.
//

import SwiftUI

struct SkillTag: View {
    enum TagType {
        case offering, seeking
    }
    
    let text: String
    let type: TagType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type == .offering ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(type == .offering ? .blue : .green)
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(type == .offering ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
        )
    }
}
