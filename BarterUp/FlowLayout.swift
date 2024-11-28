//
//  FlowLayout.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return rows.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        rows.place(in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> Rows {
        var rows: [Row] = []
        var currentRow = Row(spacing: spacing)
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRow.width + size.width + spacing > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = Row(spacing: spacing)
            }
            currentRow.add(subview, size: size)
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return Rows(rows: rows)
    }
    
    struct Row {
        var subviews: [(subview: LayoutSubview, size: CGSize)] = []
        var width: CGFloat = 0
        let spacing: CGFloat
        
        var isEmpty: Bool { subviews.isEmpty }
        
        mutating func add(_ subview: LayoutSubview, size: CGSize) {
            subviews.append((subview, size))
            width += size.width + (isEmpty ? 0 : spacing)
        }
    }
    
    struct Rows {
        var rows: [Row]
        var size: CGSize {
            let width = rows.map(\.width).max() ?? 0
            let height = rows.map { row in
                row.subviews.map(\.size.height).max() ?? 0
            }.reduce(0, +)
            return CGSize(width: width, height: height)
        }
        
        func place(in bounds: CGRect) {
            var y = bounds.minY
            for row in rows {
                var x = bounds.minX
                for (subview, size) in row.subviews {
                    subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                    x += size.width + row.spacing
                }
                y += (row.subviews.map(\.size.height).max() ?? 0)
            }
        }
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
