import Foundation
import SwiftData
import SwiftUI

@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var hexColor: String
    
    @Relationship(deleteRule: .cascade, inverse: \Notebook.folder)
    var notebooks: [Notebook] = []
    
    init(id: UUID = UUID(), name: String, hexColor: String = "#000000") {
        self.id = id
        self.name = name
        self.hexColor = hexColor
    }
}

@Model
final class Notebook {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var folder: Folder?
    
    @Relationship(deleteRule: .cascade, inverse: \Page.notebook)
    var pages: [Page] = []
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class Page {
    @Attribute(.unique) var id: UUID
    var index: Int
    var notebook: Notebook?
    
    @Relationship(deleteRule: .nullify)
    var template: Template?
    
    @Attribute(.externalStorage)
    var strokeData: Data? // PKDrawing data
    
    init(id: UUID = UUID(), index: Int, strokeData: Data? = nil) {
        self.id = id
        self.index = index
        self.strokeData = strokeData
    }
}

@Model
final class Template {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String // grid, dotted, lined, custom
    var backgroundColorHex: String
    var spacing: Double
    
    init(id: UUID = UUID(), name: String, type: String, backgroundColorHex: String = "#FFFFFF", spacing: Double = 20.0) {
        self.id = id
        self.name = name
        self.type = type
        self.backgroundColorHex = backgroundColorHex
        self.spacing = spacing
    }
}
