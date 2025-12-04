// View for adding new expenses.
// Simple form with validation and category selection.

import SwiftUI

// Custom TextField that only accepts numbers
struct NumberTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .onChange(of: text) { oldValue, newValue in
                // Filter out non-numeric characters except decimal point
                let filtered = newValue.filter { "0123456789.".contains($0) }
                // Ensure only one decimal point
                let components = filtered.components(separatedBy: ".")
                if components.count > 2 {
                    text = components[0] + "." + components[1...].joined()
                } else {
                    text = filtered
                }
            }
    }
}

struct AddExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var amount: Double?
    @State private var date: Date
    @State private var category = "Food"
    @State private var amountText = ""
    
    let categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Health", "Other"]
    
    init(preselectedDate: Date = Date()) {
        _date = State(initialValue: preselectedDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean black background
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TITLE")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            TextField("e.g., Lunch", text: $title)
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Amount Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AMOUNT")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            HStack {
                                Text("₹")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                
                                NumberTextField(text: $amountText, placeholder: "0")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .onChange(of: amountText) { oldValue, newValue in
                                        if let value = Double(newValue) {
                                            amount = value
                                        } else if newValue.isEmpty {
                                            amount = nil
                                        }
                                    }
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(categories, id: \.self) { cat in
                                    CategoryButton(
                                        category: cat,
                                        isSelected: category == cat,
                                        action: { category = cat }
                                    )
                                }
                            }
                        }
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.1))
                                .cornerRadius(12)
                                .colorScheme(.dark)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { addExpense() }
                        .fontWeight(.medium)
                        .foregroundColor((title.isEmpty || amount == nil) ? .gray : .white)
                        .disabled(title.isEmpty || amount == nil)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func addExpense() {
        let newExpense = Expense(context: viewContext)
        newExpense.id = UUID()
        newExpense.title = title
        newExpense.amount = amount ?? 0.0
        newExpense.date = date
        newExpense.category = category
        
        do {
            try viewContext.save()
            // Reset inactivity timer on user action
            UserDefaults.standard.set(Date(), forKey: "lastAppOpenTime")
            NotificationManager.shared.scheduleSmartReminders(viewContext: viewContext)
            dismiss()
        } catch {
            // Should probably handle this better in production
            print("Error saving expense: \(error)")
        }
    }
}

// Simple category button component
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: CategoryHelper.icon(for: category))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : Color(UIColor.systemGray6).opacity(0.1))
            .cornerRadius(12)
        }
    }
}
