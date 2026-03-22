import SwiftUI
import PencilKit
import SwiftData

struct CanvasView: UIViewRepresentable {
    @Bindable var page: Page
    @Binding var tool: PKTool
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = tool
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear // Let SwiftUI handle the background
        
        if let data = page.strokeData, let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = tool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(page: page)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var page: Page
        
        init(page: Page) {
            self.page = page
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update the page model with the new drawing data
            page.strokeData = canvasView.drawing.dataRepresentation()
            print("Canvas updated: Page \(page.index) stroke data size: \(page.strokeData?.count ?? 0) bytes")
        }
    }
}

// MARK: - Template Background View
struct TemplateBackgroundView: View {
    let template: Template?
    
    var body: some View {
        ZStack {
            if let template = template {
                Color(hex: template.backgroundColorHex)
                
                Canvas { context, size in
                    let spacing = CGFloat(template.spacing)
                    let strokeColor = Color.gray.opacity(0.3)
                    
                    switch template.type {
                    case "grid":
                        // Draw Grid
                        for x in stride(from: 0, through: size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            context.stroke(path, with: .color(strokeColor), lineWidth: 0.5)
                        }
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(strokeColor), lineWidth: 0.5)
                        }
                    case "lined":
                        // Draw Lines
                        for y in stride(from: spacing, through: size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(strokeColor), lineWidth: 0.5)
                        }
                    case "dotted":
                        // Draw Dots
                        for x in stride(from: spacing, through: size.width, by: spacing) {
                            for y in stride(from: spacing, through: size.height, by: spacing) {
                                let rect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                                context.fill(Path(ellipseIn: rect), with: .color(strokeColor))
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
            } else {
                Color.white
            }
        }
    }
}
