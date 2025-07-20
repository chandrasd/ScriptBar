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
                    editingScript = Script(
                        name: "",
                        content:
                            "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\""
                    )
                    showingEditor = true
                }
            }
            .padding()

            List(scriptManager.scripts, selection: $selectedScript) { script in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if script.isExecutable {
                            Image(systemName: "terminal")
                                .foregroundColor(.green)
                        }
                        Text(script.name)
                            .font(.headline)
                        Spacer()

                        ScriptActionButtons(
                            onRun: { run(script) },
                            onEdit: { edit(script) },
                            onDelete: { delete(script) }
                        )
                    }
                    // TODO: Script Description
                    Text(
                        "Created: \(script.createdAt, formatter: dateFormatter)"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private func run(_ script: Script) {
        Task {
            await scriptManager.runScript(script)
        }
    }

    private func edit(_ script: Script) {
        editingScript = script
        showingEditor = true
    }

    private func delete(_ script: Script) {
        Task {
            scriptManager.deleteScript(script)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

// TODO: refactor these buttons into a generic custom button and reuse
struct ScriptActionButtons: View {
    let onRun: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHoveringOverDelete = false
    @State private var isHoveringOverEdit = false
    @State private var isHoveringOverPlay = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onRun) {
                Image(systemName: "play.fill")
            }
            .imageScale(.large)
            .frame(width: 32, height: 32)
            .buttonStyle(.borderless)
            .background(
                isHoveringOverPlay ? Color.gray.opacity(0.1) : Color.clear
            )
            .clipShape(.buttonBorder)
            .help("Run script")
            .accessibilityLabel("Run script")
            .onHover {
                hovering in
                isHoveringOverPlay = hovering
            }

            Button(action: onEdit) {
                Image(systemName: "pencil.and.list.clipboard")
            }
            .imageScale(.large)
            .frame(width: 32, height: 32)
            .buttonStyle(.borderless)
            .background(
                isHoveringOverEdit ? Color.gray.opacity(0.1) : Color.clear
            )
            .clipShape(.buttonBorder)
            .help("Edit script")
            .accessibilityLabel("Edit Script")
            .onHover {
                hovering in
                isHoveringOverEdit = hovering
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .imageScale(.large)
            .frame(width: 32, height: 32)
            .buttonStyle(.borderless)
            .foregroundColor(isHoveringOverDelete ? .red : .gray)
            .background(
                isHoveringOverDelete ? Color.gray.opacity(0.1) : Color.clear
            )
            .clipShape(.buttonBorder)
            .help("Delete script")
            .accessibilityLabel("Delete script")
            .onHover { hovering in
                isHoveringOverDelete = hovering
            }
        }
    }
}

#Preview {
    ScriptManagerView(
        scriptManager: ScriptManager(),
        onRefresh: {}
    )
}
