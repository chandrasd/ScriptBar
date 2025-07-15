//
//  ScriptEditorView.swift
//  scripter
//
//  Created by Chandra Dasari on 7/11/25.
//
import SwiftUI

struct ScriptEditorView: View {
    @State private var script: Script
    let onSave: (Script) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(script: Script, onSave: @escaping (Script) -> Void) {
        self._script = State(initialValue: script)
        self.onSave = onSave
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Script Editor")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                Button("Save") {
                    onSave(script)
                }
                .buttonStyle(.borderedProminent)
                .disabled(script.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            TextField("Script Name", text: $script.name)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading) {
                Text("Script Content:")
                    .font(.headline)
                
                TextEditor(text: $script.content)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .border(Color.gray.opacity(0.3))
            }
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}



