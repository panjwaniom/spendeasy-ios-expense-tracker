import SwiftUI

struct CategoryHelper {
    static func icon(for category: String) -> String {
        switch category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Shopping": return "bag.fill"
        case "Bills": return "doc.text.fill"
        case "Entertainment": return "tv.fill"
        case "Health": return "heart.fill"
        case "Other": return "ellipsis.circle.fill"
        default: return "tag.fill"
        }
    }
    
    static func color(for category: String) -> Color {
        switch category {
        case "Food": return Color(hex: "ff6b6b")        // Vibrant red
        case "Transport": return Color(hex: "4ecdc4")   // Teal
        case "Shopping": return Color(hex: "ff6bcb")    // Pink
        case "Bills": return Color(hex: "ffa500")       // Orange
        case "Entertainment": return Color(hex: "a78bfa") // Purple
        case "Health": return Color(hex: "51cf66")      // Green
        case "Other": return Color(hex: "94a3b8")       // Slate gray
        default: return Color(hex: "94a3b8")
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
