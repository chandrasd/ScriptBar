//
//  ScriptManagerView.swift
//  scripter
//
//  Created by Chandra Dasari on 7/11/25.
//
import SwiftUI

struct ScriptManagerView: View {
    @ObservedObject var scriptManager: ScriptManager
    let onRefresh: () -> Void
    @State private var selectedScript: Script?
    @State private var editingScript: Script?
    @State private var showingEditor = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Scripts")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button("New Script") {
                    editingScript = Script(name: "", content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")
                    showingEditor = true
                }
            }
            .padding()
            
            List(scriptManager.scripts, selection: $selectedScript) { script in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(script.name)
                            .font(.headline)
                        Spacer()
                        if script.isExecutable {
                            Image(systemName: "terminal")
                                .foregroundColor(.green)
                        }
                    }
                    Text("Created: \(script.createdAt, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contextMenu {
                    Button("Edit") {
                        editingScript = script
                        showingEditor = true
                    }
                    Button("Run") {
                        Task {
                            await scriptManager.runScript(script)
                        }
                    }
                    Button("Delete", role: .destructive) {
                        scriptManager.deleteScript(script)
                        onRefresh()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let script = editingScript {
                ScriptEditorView(script: script) { updatedScript in
                    scriptManager.saveScript(updatedScript)
                    onRefresh()
                    showingEditor = false
                    editingScript = nil
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}


