import SwiftUI
import Charts

struct DonutChartView: View {
    let expenses: [Expense]
    @State private var selectedCategories: Set<String> = []
    @State private var tappedAngle: Double? = nil
    
    var categoryTotals: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category ?? "Other" }
        return grouped.map { category, expenses in
            (category: category, amount: expenses.reduce(0) { $0 + $1.amount })
        }
        .sorted { $0.amount > $1.amount }
    }
    
    var totalAmount: Double {
        if selectedCategories.isEmpty {
            return categoryTotals.reduce(0) { $0 + $1.amount }
        } else {
            return categoryTotals
                .filter { selectedCategories.contains($0.category) }
                .reduce(0) { $0 + $1.amount }
        }
    }
    
    var selectedCategoryNames: String {
        if selectedCategories.isEmpty {
            return "Total"
        } else if selectedCategories.count == 1 {
            return selectedCategories.first ?? "Total"
        } else {
            return "\(selectedCategories.count) Categories"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart with tap to multi-select
            ZStack {
                // The actual chart
                Chart(categoryTotals, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(CategoryHelper.color(for: item.category))
                    .opacity(selectedCategories.isEmpty || selectedCategories.contains(item.category) ? 1.0 : 0.2)
                }
                .frame(height: 280)
                
                // Invisible overlay for tap detection
                Circle()
                    .fill(Color.clear)
                    .frame(width: 280, height: 280)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                handleTap(at: value.location)
                            }
                    )
                
                // Center display
                VStack(spacing: 6) {
                    Text(selectedCategoryNames)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    Text(totalAmount, format: .currency(code: "INR"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if selectedCategories.count > 1 {
                        Text("Combined")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategories)
            }
            .frame(height: 280)
            .padding(.vertical, 20)
        }
    }
    
    // Algorithm: Convert tap location to category selection
    // 1. Find where user tapped relative to chart center
    // 2. Calculate distance to ensure tap is on the donut ring (not center or outside)
    // 3. Convert tap position to angle (0-360 degrees)
    // 4. Map that angle to the corresponding category slice
    // 5. Toggle that category's selection state
    private func handleTap(at location: CGPoint) {
        // Step 1: Calculate center of the chart (140 is half of 280)
        let center = CGPoint(x: 140, y: 140)
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        // Step 2: Calculate distance from center
        let distance = sqrt(dx * dx + dy * dy)
        
        // Check if tap is within the donut ring (between inner and outer radius)
        // Outer radius is ~140, inner radius is ~86 (140 * 0.618 for golden ratio)
        guard distance >= 70 && distance <= 140 else { return }
        
        // Step 3: Calculate angle from tap position
        var angle = atan2(dy, dx) * 180 / .pi
        
        // Normalize to 0-360 range
        if angle < 0 { angle += 360 }
        
        // Adjust for chart starting at top (rotate by -90 degrees)
        angle = (angle + 90).truncatingRemainder(dividingBy: 360)
        
        // Step 4: Find which category this angle corresponds to
        var currentAngle: Double = 0
        let total = categoryTotals.reduce(0) { $0 + $1.amount }
        
        for item in categoryTotals {
            let itemAngle = (item.amount / total) * 360
            if angle >= currentAngle && angle < currentAngle + itemAngle {
                // Step 5: Toggle selection for this category
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if selectedCategories.contains(item.category) {
                        selectedCategories.remove(item.category)
                    } else {
                        selectedCategories.insert(item.category)
                    }
                }
                break
            }
            currentAngle += itemAngle
        }
    }
}
