#if canImport(UIKit)
import CoreImage
import SnapshotTesting
import UIKit

/// Renders a view controller for a capture, without a host application.
///
/// A test bundle with no host app has no render server, so the only way to get pixels is
/// `CALayer.render(in:)`. That draws the layer tree on the CPU and skips everything the render
/// server does on its own: Core Animation filters and backdrops. Liquid Glass is built from exactly
/// those, so without help a toolbar's symbol comes out white (its `vibrantColorMatrix` filter is
/// what darkens it) and the glass platter behind it comes out missing.
///
/// This renderer therefore:
/// - puts the controller in a real window and lets the run loop turn before drawing, so platform
///   views (switches, segmented controls) are created and `onAppear` and `task` have run;
/// - re-measures a fitting height once the view is in the window, where it has its final size;
/// - for the render only, draws each layer under a `vibrantColorMatrix` filter in the label color
///   and paints each glass shape with a flat fill and a hairline, then puts every layer back.
@MainActor
enum CaptureRenderer {

    /// How long the run loop turns before the view is drawn.
    static var settleDuration: TimeInterval = 0.02

    static func image(
        of viewController: UIViewController,
        config: ViewImageConfig,
        fittingWidth: CGFloat?
    ) -> UIImage {
        var size = config.size ?? viewController.view.frame.size
        if let fittingWidth { size.width = fittingWidth }
        let window = CaptureWindow(frame: CGRect(origin: .zero, size: size), safeArea: config.safeArea)
        let root = UIViewController()
        window.rootViewController = root
        root.view.frame = window.bounds
        root.addChild(viewController)
        override(viewController, with: config.traits)
        viewController.view.frame = root.view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.view.addSubview(viewController.view)
        viewController.didMove(toParent: root)
        window.isHidden = false
        defer {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
            window.rootViewController = nil
            window.isHidden = true
        }

        settle(window)
        if let fittingWidth {
            let fitting = viewController.view.sizeThatFits(CGSize(width: fittingWidth, height: .greatestFiniteMagnitude))
            let height = max(1, ceil(fitting.height))
            if height != size.height {
                size = CGSize(width: fittingWidth, height: height)
                window.frame = CGRect(origin: .zero, size: size)
                root.view.frame = window.bounds
                settle(window)
            }
        }

        let style = config.traits.userInterfaceStyle == .unspecified
            ? viewController.traitCollection.userInterfaceStyle
            : config.traits.userInterfaceStyle
        let scale = config.traits.displayScale > 0 ? config.traits.displayScale : window.screen.scale
        let restore = LayerEffects.flatten(window.layer, dark: style == .dark, scale: scale)
        defer { restore() }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    /// Carries over the traits a ``SnapshotDevice`` or a component capture sets.
    private static func override(_ viewController: UIViewController, with traits: UITraitCollection) {
        if traits.userInterfaceStyle != .unspecified {
            viewController.traitOverrides.userInterfaceStyle = traits.userInterfaceStyle
        }
        if traits.displayScale > 0 {
            viewController.traitOverrides.displayScale = traits.displayScale
        }
        if traits.preferredContentSizeCategory != .unspecified {
            viewController.traitOverrides.preferredContentSizeCategory = traits.preferredContentSizeCategory
        }
        if traits.horizontalSizeClass != .unspecified {
            viewController.traitOverrides.horizontalSizeClass = traits.horizontalSizeClass
        }
        if traits.verticalSizeClass != .unspecified {
            viewController.traitOverrides.verticalSizeClass = traits.verticalSizeClass
        }
    }

    private static func settle(_ window: UIWindow) {
        window.setNeedsLayout()
        window.layoutIfNeeded()
        let end = Date().addingTimeInterval(settleDuration)
        repeat {
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.005))
            window.layoutIfNeeded()
        } while Date() < end
        CATransaction.flush()
    }

    private final class CaptureWindow: UIWindow {
        private let insets: UIEdgeInsets

        init(frame: CGRect, safeArea: UIEdgeInsets) {
            insets = safeArea
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var safeAreaInsets: UIEdgeInsets { insets }
    }
}

/// Stand-ins, for one CPU render, for the Core Animation effects `render(in:)` cannot draw.
@MainActor
enum LayerEffects {

    /// Rewrites the tree under `layer` and returns the closure that puts it back.
    static func flatten(_ layer: CALayer, dark: Bool, scale: CGFloat) -> () -> Void {
        var undo: [() -> Void] = []
        visit(layer, root: layer, insideGlass: false, dark: dark, scale: scale, undo: &undo)
        return { for step in undo.reversed() { step() } }
    }

    private static let context = CIContext()

    private static func filterNames(_ layer: CALayer) -> [String] {
        (layer.filters ?? []).map { String(describing: $0) }
    }

    private static func visit(_ layer: CALayer, root: CALayer, insideGlass: Bool, dark: Bool, scale: CGFloat, undo: inout [() -> Void]) {
        let names = filterNames(layer)
        if names.contains("vibrantColorMatrix"), replaceWithRecolored(layer, root: root, matrix: labelMatrix(dark: dark), scale: scale, undo: &undo) {
            return
        }

        let isGlass = names.contains("glassBackground")
        if insideGlass, String(describing: type(of: layer)).contains("SDFElementLayer"), layer.bounds.width > 0, layer.bounds.height > 0 {
            let savedColor = layer.backgroundColor
            let savedRadius = layer.cornerRadius
            let savedCurve = layer.cornerCurve
            let savedBorder = (layer.borderWidth, layer.borderColor)
            layer.borderWidth = 1 / scale
            layer.borderColor = dark ? UIColor(white: 1, alpha: 0.12).cgColor : UIColor(white: 0, alpha: 0.08).cgColor
            layer.backgroundColor = dark
                ? UIColor(white: 0.22, alpha: 0.9).cgColor
                : UIColor(white: 1, alpha: 0.9).cgColor
            if layer.cornerRadius == 0 { layer.cornerRadius = min(layer.bounds.width, layer.bounds.height) / 2 }
            layer.cornerCurve = .continuous
            undo.append {
                layer.backgroundColor = savedColor
                layer.cornerRadius = savedRadius
                layer.cornerCurve = savedCurve
                layer.borderWidth = savedBorder.0
                layer.borderColor = savedBorder.1
            }
        }

        for sublayer in layer.sublayers ?? [] {
            visit(sublayer, root: root, insideGlass: insideGlass || isGlass, dark: dark, scale: scale, undo: &undo)
        }
    }

    /// Draws the layer and everything under it on its own, runs a color matrix over the pixels, and
    /// shows that image on top of everything, where the layer is, for the render.
    ///
    /// On top, because the render server shows these layers through a portal above the glass; in the
    /// tree itself they sit below it, and a flat fill standing in for the glass would cover them.
    private static func replaceWithRecolored(
        _ layer: CALayer, root: CALayer, matrix: [CGFloat], scale: CGFloat, undo: inout [() -> Void]
    ) -> Bool {
        let bounds = layer.bounds
        let opacity = visibleOpacity(of: layer, below: root)
        guard bounds.width > 0, bounds.height > 0, opacity > 0.01 else { return false }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let drawn = UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            context.cgContext.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            layer.render(in: context.cgContext)
        }
        guard let source = drawn.cgImage, let recolored = apply(matrix, to: source) else { return false }

        let stand = CALayer()
        stand.frame = layer.convert(bounds, to: root)
        stand.opacity = opacity
        stand.contents = recolored
        stand.contentsGravity = .resize
        stand.contentsScale = scale
        root.addSublayer(stand)
        let wasHidden = layer.isHidden
        layer.isHidden = true
        undo.append {
            stand.removeFromSuperlayer()
            layer.isHidden = wasHidden
        }
        return true
    }

    private static func visibleOpacity(of layer: CALayer, below root: CALayer) -> Float {
        var opacity: Float = 1
        var current: CALayer? = layer
        while let step = current, step !== root {
            if step.isHidden { return 0 }
            opacity *= step.opacity
            current = step.superlayer
        }
        return opacity
    }

    /// The color a monochrome glyph on glass resolves to.
    ///
    /// The filter's own matrix is no help: glass picks it from the brightness of what is behind
    /// (`LumaTracker`), which only the render server measures, so without one it always assumes a
    /// dark backdrop and turns the glyph white. A light screen gets the dark label color instead.
    private static func labelMatrix(dark: Bool) -> [CGFloat] {
        let color = UIColor.label.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light))
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [0, 0, 0, 0, r, 0, 0, 0, 0, g, 0, 0, 0, 0, b, 0, 0, 0, a, 0]
    }

    private static func apply(_ m: [CGFloat], to image: CGImage) -> CGImage? {
        let input = CIImage(cgImage: image)
        guard let filter = CIFilter(name: "CIColorMatrix") else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: m[0], y: m[1], z: m[2], w: m[3]), forKey: "inputRVector")
        filter.setValue(CIVector(x: m[5], y: m[6], z: m[7], w: m[8]), forKey: "inputGVector")
        filter.setValue(CIVector(x: m[10], y: m[11], z: m[12], w: m[13]), forKey: "inputBVector")
        filter.setValue(CIVector(x: m[15], y: m[16], z: m[17], w: m[18]), forKey: "inputAVector")
        filter.setValue(CIVector(x: m[4], y: m[9], z: m[14], w: m[19]), forKey: "inputBiasVector")
        guard let output = filter.outputImage else { return nil }
        return context.createCGImage(output, from: input.extent)
    }
}
#endif
