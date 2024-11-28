//
//  FlowLayout.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrangeSubviews(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = arrangeSubviews(sizes: sizes, proposal: proposal).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let width = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var maxY: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for size in sizes {
            if currentPosition.x + size.width > width {
                // Move to next row
                currentPosition.x = 0
                currentPosition.y = maxY + spacing
            }
            
            offsets.append(currentPosition)
            
            // Update position and track maximum width/height
            currentPosition.x += size.width + spacing
            maxWidth = max(maxWidth, currentPosition.x)
            maxY = max(maxY, currentPosition.y + size.height)
        }
        
        return (offsets, CGSize(width: maxWidth, height: maxY))
    }
}

// Preview provider for testing
struct FlowLayout_Previews: PreviewProvider {
    static var previews: some View {
        FlowLayout(spacing: 8) {
            ForEach(0..<10) { index in
                Text("Item \(index)")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

// Example usage view
struct FlowLayoutExample: View {
    let items = ["Swift", "SwiftUI", "iOS Development", "Xcode", "UIKit", "Core Data", "Combine"]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
            }
        }
        .padding()
    }
}
