//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText: String = ""
    @State private var showAlert = false
    
    let email = "ieremiay@gmail.com"
    let subject = "Відгук про FlexMusic"
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Залиште свій відгук або пропозицію:")
                    .font(.headline)
                    .foregroundColor(.primary)
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground).opacity(0.7))
                    TextEditor(text: $feedbackText)
                        .padding(6)
                        .background(Color.clear)
                        .cornerRadius(12)
                        .frame(minHeight: 150)
                }
                Spacer()
                Button(action: sendFeedback) {
                    Label("Відправити", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color.clear)
            .navigationTitle("Зворотний зв'язок")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") { dismiss() }
                }
            }
            .alert("Не вдалося відкрити поштовий клієнт", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .background(Color.clear)
    }
    
    func sendFeedback() {
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailto = "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url) { success in
                if success { dismiss() }
                else { showAlert = true }
            }
        } else {
            showAlert = true
        }
    }
}

#Preview {
    FeedbackView()
} 
