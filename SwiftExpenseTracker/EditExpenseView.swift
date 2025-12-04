// View for editing existing expenses.
// Allows modifying details or deleting the expense.

import SwiftUI

struct EditExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var expense: Expense
    
    @State private var title: String
    @State private var amount: Double
    @State private var amountText: String
    @State private var date: Date
    @State private var category: String
    @State private var showDeleteAlert = false
    
    let categories = ["Food", "Transport", "Shopping", "Bills", "Entertainment", "Health", "Other"]
    
    init(expense: Expense) {
        self.expense = expense
        _title = State(initialValue: expense.title ?? "")
        _amount = State(initialValue: expense.amount)
        _amountText = State(initialValue: String(format: "%.2f", expense.amount))
        _date = State(initialValue: expense.date ?? Date())
        _category = State(initialValue: expense.category ?? "Food")
    }
    
    var body: some View {
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
                    
                    // Delete Button
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete Expense")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding(20)
            }
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { updateExpense() }
                    .fontWeight(.medium)
                    .foregroundColor((title.isEmpty || amount == 0) ? .gray : .white)
                    .disabled(title.isEmpty || amount == 0)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteExpense() }
        } message: {
            Text("Are you sure? This cannot be undone.")
        }
    }
    
    private func updateExpense() {
        expense.title = title
        expense.amount = amount
        expense.date = date
        expense.category = category
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error updating expense: \(error)")
        }
    }
    
    private func deleteExpense() {
        viewContext.delete(expense)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
}
