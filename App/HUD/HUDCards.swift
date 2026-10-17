import SwiftUI
import StoreSimKit

/// The plum logo drawn from `Brand.mark`.
struct PlumMarkView: View {
    var size: CGFloat = 28
    var body: some View {
        let mark = Brand.mark
        ZStack {
            Circle().fill(mark.body.color)
            Circle().fill(mark.highlight.color)
                .frame(width: size * 0.25, height: size * 0.25)
                .offset(x: -size * 0.15, y: -size * 0.15)
            Ellipse().fill(mark.leaf.color)
                .frame(width: size * 0.38, height: size * 0.2)
                .rotationEffect(.degrees(-mark.leafAngle))
                .offset(x: size * 0.18, y: -size * 0.46)
        }
        .frame(width: size, height: size)
    }
}

struct BrandCard: View {
    var compact = false
    var body: some View {
        HStack(spacing: 10) {
            PlumMarkView(size: compact ? 22 : 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(Brand.name).font(compact ? .headline : .title2.weight(.semibold))
                if !compact { Text(Brand.tagline).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

struct SelectionCard: View {
    var selection: Selection?
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let selection {
                Text(selection.displayName).font(.headline)
                if !selection.kindName.isEmpty {
                    Text(selection.kindName).font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Nothing selected").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 140, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
