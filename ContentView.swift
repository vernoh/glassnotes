import SwiftUI
import SwiftData
import PencilKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \Notebook.createdAt, order: .reverse) private var notebooks: [Notebook]
    
    @State private var selectedFolder: Folder?
    @State private var selectedNotebook: Notebook?
    @State private var showingNewFolderSheet = false
    @State private var showingNewNotebookSheet = false
    
    // Tools
    @State private var currentTool: PKTool = PKInkingTool(.pen, color: .black, width: 2)
    @State private var currentPageIndex = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Folders
            List(selection: $selectedFolder) {
                Section("Folders") {
                    ForEach(folders) { folder in
                        NavigationLink(value: folder) {
                            Label(folder.name, systemImage: "folder.fill")
                                .foregroundColor(Color(hex: folder.hexColor))
                        }
                    }
                    .onDelete(perform: deleteFolders)
                }
                
                Button(action: { showingNewFolderSheet = true }) {
                    Label("New Folder", systemImage: "plus.circle")
                }
            }
            .navigationTitle("GlassNotes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                NewFolderSheet()
            }
        } content: {
            // Content: Notebooks Grid
            if let folder = selectedFolder {
                NotebookGridView(folder: folder, selectedNotebook: $selectedNotebook)
                    .navigationTitle(folder.name)
            } else {
                Text("Select a Folder")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            // Detail: Notebook Canvas
            if let notebook = selectedNotebook {
                NotebookCanvasView(notebook: notebook, currentTool: $currentTool, currentPageIndex: $currentPageIndex)
            } else {
                Text("Select a Notebook")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func deleteFolders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(folders[index])
            }
        }
    }
}

// MARK: - Notebook Grid View
struct NotebookGridView: View {
    let folder: Folder
    @Binding var selectedNotebook: Notebook?
    @State private var showingNewNotebookSheet = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200))], spacing: 20) {
                ForEach(folder.notebooks) { notebook in
                    Button(action: { selectedNotebook = notebook }) {
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 140, height: 180)
                                    .shadow(radius: 5)
                                
                                Text("\(notebook.pages.count) Pages")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 100)
                            }
                            
                            Text(notebook.name)
                                .font(.headline)
                                .lineLimit(1)
                                .padding(.top, 4)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Rename") { /* Rename Logic */ }
                        Button("Delete", role: .destructive) {
                            modelContext.delete(notebook)
                        }
                    }
                }
                
                Button(action: { showingNewNotebookSheet = true }) {
                    VStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                            .frame(width: 140, height: 180)
                            .overlay(Image(systemName: "plus").font(.largeTitle))
                        
                        Text("New Notebook")
                            .font(.headline)
                            .padding(.top, 4)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .sheet(isPresented: $showingNewNotebookSheet) {
            NewNotebookSheet(folder: folder)
        }
    }
}

// MARK: - Notebook Canvas View (Phase 2 & 3 Integration)
struct NotebookCanvasView: View {
    @Bindable var notebook: Notebook
    @Binding var currentTool: PKTool
    @Binding var currentPageIndex: Int
    @Environment(\.modelContext) private var modelContext
    @Query private var templates: [Template]
    
    var body: some View {
        ZStack {
            // Background Layer
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            // Content Layer: Pages
            if notebook.pages.indices.contains(currentPageIndex) {
                let page = notebook.pages[currentPageIndex]
                ZStack {
                    TemplateBackgroundView(template: page.template)
                    CanvasView(page: page, tool: $currentTool)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 10)
                .padding()
            } else {
                Text("No pages in this notebook")
                    .foregroundStyle(.secondary)
            }
            
            // UI Layer: Floating Toolbar (Phase 3)
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    // Tool Selection
                    ToolButton(icon: "pencil", tool: .pen, currentTool: $currentTool)
                    ToolButton(icon: "pencil.tip", tool: .highlighter, currentTool: $currentTool)
                    ToolButton(icon: "eraser", tool: .eraser, currentTool: $currentTool)
                    
                    Divider().frame(height: 30)
                    
                    // Template Selector (Phase 5)
                    Menu {
                        ForEach(templates) { template in
                            Button(template.name) {
                                if notebook.pages.indices.contains(currentPageIndex) {
                                    notebook.pages[currentPageIndex].template = template
                                    print("Template applied: \(template.name) to Page \(currentPageIndex)")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "doc.plaintext")
                            .font(.title3)
                    }
                    
                    Divider().frame(height: 30)
                    
                    // Page Control
                    HStack {
                        Button(action: { currentPageIndex = max(0, currentPageIndex - 1) }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(currentPageIndex == 0)
                        
                        Text("Page \(currentPageIndex + 1) / \(max(1, notebook.pages.count))")
                            .font(.caption.bold())
                        
                        Button(action: { currentPageIndex = min(notebook.pages.count - 1, currentPageIndex + 1) }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(currentPageIndex >= notebook.pages.count - 1)
                    }
                    
                    Divider().frame(height: 30)
                    
                    // Add Page
                    Button(action: addNewPage) {
                        Image(systemName: "plus.square.on.square")
                            .font(.title3)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            ensureTemplatesExist()
        }
    }
    
    private func addNewPage() {
        let newPage = Page(index: notebook.pages.count)
        // Default to the template of the previous page if available
        if let lastPage = notebook.pages.last {
            newPage.template = lastPage.template
        }
        notebook.pages.append(newPage)
        currentPageIndex = notebook.pages.count - 1
        print("Page created: Index \(newPage.index) for Notebook \(notebook.name)")
    }
    
    private func ensureTemplatesExist() {
        if templates.isEmpty {
            let defaults = [
                Template(name: "Blank", type: "blank"),
                Template(name: "Grid (Small)", type: "grid", spacing: 20),
                Template(name: "Grid (Large)", type: "grid", spacing: 40),
                Template(name: "Lined", type: "lined", spacing: 30),
                Template(name: "Dotted", type: "dotted", spacing: 25)
            ]
            for template in defaults {
                modelContext.insert(template)
            }
            print("Default templates created")
        }
    }
}

// MARK: - Subviews & Helpers
struct ToolButton: View {
    let icon: String
    let tool: ToolType
    @Binding var currentTool: PKTool
    
    enum ToolType {
        case pen, highlighter, eraser
    }
    
    var body: some View {
        Button(action: {
            switch tool {
            case .pen: currentTool = PKInkingTool(.pen, color: .black, width: 2)
            case .highlighter: currentTool = PKInkingTool(.marker, color: .yellow, width: 20)
            case .eraser: currentTool = PKEraserTool(.vector)
            }
            print("Tool selected: \(tool)")
        }) {
            Image(systemName: icon)
                .font(.title2)
                .padding(10)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .clipShape(Circle())
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(), value: isSelected)
        }
    }
    
    private var isSelected: Bool {
        switch tool {
        case .pen: return (currentTool as? PKInkingTool)?.inkType == .pen
        case .highlighter: return (currentTool as? PKInkingTool)?.inkType == .marker
        case .eraser: return currentTool is PKEraserTool
        }
    }
}

struct NewFolderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hexColor = "#007AFF"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Folder Name", text: $name)
                ColorPicker("Folder Color", selection: Binding(
                    get: { Color(hex: hexColor) },
                    set: { hexColor = $0.toHex() ?? "#007AFF" }
                ))
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newFolder = Folder(name: name, hexColor: hexColor)
                        modelContext.insert(newFolder)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct NewNotebookSheet: View {
    let folder: Folder
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Notebook Name", text: $name)
            }
            .navigationTitle("New Notebook")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let newNotebook = Notebook(name: name)
                        newNotebook.folder = folder
                        // Add an initial page
                        let firstPage = Page(index: 0)
                        newNotebook.pages.append(firstPage)
                        modelContext.insert(newNotebook)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// Extension to handle Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        if components.count >= 4 { a = Float(components[3]) }
        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(a * 255), lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
