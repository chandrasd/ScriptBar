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

struct ScriptActionButtons: View {
    let onRun: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HoverIconButton(
                systemImageName: "play.fill",
                tooltip: "Run script",
                accessibilityLabel: "Run script",
                action: onRun,
                hoverColor: .gray.opacity(0.1),
                foregroundColor: { _ in .primary }
            )

            HoverIconButton(
                systemImageName: "pencil.and.list.clipboard",
                tooltip: "Edit script",
                accessibilityLabel: "Edit script",
                action: onEdit,
                hoverColor: .gray.opacity(0.1),
                foregroundColor: { _ in .primary }
            )

            HoverIconButton(
                systemImageName: "trash",
                tooltip: "Delete script",
                accessibilityLabel: "Delete script",
                action: onDelete,
                hoverColor: .gray.opacity(0.1),
                foregroundColor: { hovering in hovering ? .red : .primary }
            )
        }
    }
}

struct HoverIconButton: View {
    let systemImageName: String
    let tooltip: String
    let accessibilityLabel: String
    let action: () -> Void
    let hoverColor: Color
    let foregroundColor: (Bool) -> Color

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .imageScale(.large)
                .frame(width: 32, height: 32)
                .foregroundColor(foregroundColor(isHovering))
                .background(isHovering ? Color.gray.opacity(0.1) : Color.clear)
                .clipShape(.buttonBorder)
        }
        .buttonStyle(.borderless)
        .help(tooltip)
        .accessibilityLabel(accessibilityLabel)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    ScriptManagerView(
        scriptManager: ScriptManager(),
        onRefresh: {}
    )
}
