// Main dashboard view.
// Handles date navigation, expense listing, and chart visualization.

import SwiftUI
import CoreData
import Charts

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        animation: .default)
    private var allExpenses: FetchedResults<Expense>
    
    @State private var showingAddExpense = false
    @State private var selectedDate = Date()
    @State private var timeRange: TimeRange = .day // Default to Day view
    @State private var showDatePicker = false
    @State private var selectedCategory: String? = nil
    
    enum TimeRange: String, CaseIterable {
        case day = "Day"
        case month = "Month"
    }
    
    var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        return allExpenses.filter { expense in
            guard let date = expense.date else { return false }
            if timeRange == .day {
                return calendar.isDate(date, inSameDayAs: selectedDate)
            } else {
                return calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
            }
        }
    }
    
    var categoryFilteredExpenses: [Expense] {
        guard let category = selectedCategory else { return [] }
        return filteredExpenses.filter { $0.category == category }
    }
    
    private var canNavigateForward: Bool {
        let calendar = Calendar.current
        let component: Calendar.Component = timeRange == .day ? .day : .month
        if let nextDate = calendar.date(byAdding: component, value: 1, to: selectedDate) {
            return nextDate <= Date()
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background: Pure matte black for a clean, professional look
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Segmented Control
                        Picker("Time Range", selection: $timeRange.animation(.easeInOut(duration: 0.2))) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .onChange(of: timeRange) { oldValue, newValue in
                            withAnimation { selectedCategory = nil }
                        }
                        
                        // Date Navigation
                        HStack {
                            Button(action: { moveDate(by: -1) }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                            
                            // Date Title (Tappable in Day mode)
                            Button(action: {
                                if timeRange == .day { showDatePicker = true }
                            }) {
                                HStack(spacing: 8) {
                                    Text(dateTitle)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    if timeRange == .day {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .disabled(timeRange == .month)
                            
                            Spacer()
                            
                            Button(action: { moveDate(by: 1) }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(canNavigateForward ? .white : .gray.opacity(0.3))
                                    .frame(width: 44, height: 44)
                            }
                            .disabled(!canNavigateForward)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    .background(Color.black)
                    
                    // Main Content Area
                    ScrollView {
                        VStack(spacing: 24) {
                            if filteredExpenses.isEmpty {
                                emptyStateView
                            } else {
                                if let category = selectedCategory {
                                    categoryDetailView(category: category)
                                } else {
                                    // Chart
                                    DonutChartView(expenses: filteredExpenses)
                                        .padding(.top, 10)
                                    
                                    // Breakdown List
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("Spending by Category")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 20)
                                        
                                        ForEach(groupedExpenses, id: \.category) { item in
                                            Button(action: {
                                                withAnimation { selectedCategory = item.category }
                                            }) {
                                                CategoryBreakdownRow(
                                                    category: item.category,
                                                    amount: item.amount,
                                                    percentage: Int((item.amount / totalAmount) * 100),
                                                    transactionCount: item.count
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    // Swipe Gestures for Navigation
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    // Swipe Left -> Next
                                    if canNavigateForward { moveDate(by: 1) }
                                } else if value.translation.width > 50 {
                                    // Swipe Right -> Previous
                                    moveDate(by: -1)
                                }
                            }
                    )
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddExpense = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(preselectedDate: selectedDate)
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            .onAppear {
                NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleDailyReminder()
                NotificationManager.shared.checkInactivity()
                NotificationManager.shared.scheduleSmartReminders(viewContext: viewContext)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private func categoryDetailView(category: String) -> some View {
        VStack(spacing: 20) {
            // Back Action
            Button(action: { withAnimation { selectedCategory = nil } }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back to Overview")
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            }
            
            // Header
            VStack(spacing: 8) {
                Image(systemName: CategoryHelper.icon(for: category))
                    .font(.system(size: 40))
                    .foregroundColor(CategoryHelper.color(for: category))
                    .padding()
                    .background(Circle().fill(Color(UIColor.systemGray6).opacity(0.1)))
                
                Text(category)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                let total = groupedExpenses.first(where: { $0.category == category })?.amount ?? 0
                Text(total, format: .currency(code: "INR"))
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.vertical)
            
            // List
            LazyVStack(spacing: 12) {
                ForEach(categoryFilteredExpenses) { expense in
                    NavigationLink(destination: EditExpenseView(expense: expense)) {
                        ExpenseRow(expense: expense)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text("No expenses yet")
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(height: 300)
    }
    
    // MARK: - Helpers
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        if timeRange == .day {
            formatter.dateStyle = .medium
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }
    
    private func moveDate(by value: Int) {
        let component: Calendar.Component = timeRange == .day ? .day : .month
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: selectedDate) {
            if newDate <= Date() {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedDate = newDate
                    selectedCategory = nil
                }
            }
        }
    }
    
    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var groupedExpenses: [(category: String, amount: Double, count: Int)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.category ?? "Other" }
        return grouped.map { category, expenses in
            (category: category, amount: expenses.reduce(0) { $0 + $1.amount }, count: expenses.count)
        }.sorted { $0.amount > $1.amount }
    }
}

// Simple row for category list
struct CategoryBreakdownRow: View {
    let category: String
    let amount: Double
    let percentage: Int
    let transactionCount: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(CategoryHelper.color(for: category))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                Text("\(transactionCount) transactions")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount, format: .currency(code: "INR"))
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                Text("\(percentage)%")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// Simple row for individual expenses
struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            Image(systemName: CategoryHelper.icon(for: expense.category ?? "Other"))
                .foregroundColor(CategoryHelper.color(for: expense.category ?? "Other"))
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(expense.title ?? "Untitled")
                    .foregroundColor(.white)
                if let date = expense.date {
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(expense.amount, format: .currency(code: "INR"))
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.1))
        .cornerRadius(12)
    }
}

// Date picker sheet
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}


