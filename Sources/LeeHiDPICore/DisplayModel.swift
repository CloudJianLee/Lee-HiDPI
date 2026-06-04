import Foundation

public struct PixelSize: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        precondition(width > 0, "width must be positive")
        precondition(height > 0, "height must be positive")
        self.width = width
        self.height = height
    }

    public var aspectRatio: Double {
        Double(width) / Double(height)
    }

    public var description: String {
        "\(width)x\(height)"
    }
}

public struct DisplayDescriptor: Equatable, Sendable {
    public var displayID: UInt32
    public var name: String
    public var nativePixels: PixelSize
    public var logicalPoints: PixelSize?
    public var vendorID: UInt32?
    public var productID: UInt32?
    public var serialNumber: UInt32?
    public var isBuiltin: Bool

    public init(
        displayID: UInt32,
        name: String,
        nativePixels: PixelSize,
        logicalPoints: PixelSize? = nil,
        vendorID: UInt32? = nil,
        productID: UInt32? = nil,
        serialNumber: UInt32? = nil,
        isBuiltin: Bool = false
    ) {
        self.displayID = displayID
        self.name = name
        self.nativePixels = nativePixels
        self.logicalPoints = logicalPoints
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        self.isBuiltin = isBuiltin
    }

    public var canBuildDisplayOverride: Bool {
        vendorID != nil && productID != nil && !isBuiltin
    }

    public var isCurrentlyHiDPI: Bool {
        guard let logicalPoints else {
            return false
        }

        return nativePixels.width >= logicalPoints.width * 2
            && nativePixels.height >= logicalPoints.height * 2
    }
}

public struct HiDPIMode: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var logicalPoints: PixelSize
    public var backingPixels: PixelSize
    public var scaleFactor: Int

    public init(logicalPoints: PixelSize, scaleFactor: Int = 2) {
        precondition(scaleFactor > 0, "scaleFactor must be positive")
        self.logicalPoints = logicalPoints
        self.scaleFactor = scaleFactor
        self.backingPixels = PixelSize(
            width: logicalPoints.width * scaleFactor,
            height: logicalPoints.height * scaleFactor
        )
    }

    public var description: String {
        "\(logicalPoints) HiDPI（\(backingPixels) 渲染）"
    }
}

public struct HiDPIGenerationPolicy: Equatable, Sendable {
    public var minimumLogicalWidth: Int
    public var maximumBackingPixelMultiplier: Double
    public var preserveAspectRatioTolerance: Double
    public var preferredLogicalWidths: [Int]

    public init(
        minimumLogicalWidth: Int = 960,
        maximumBackingPixelMultiplier: Double = 2.0,
        preserveAspectRatioTolerance: Double = 0.01,
        preferredLogicalWidths: [Int] = [
            960, 1024, 1152, 1280, 1366, 1440, 1536,
            1600, 1680, 1728, 1920, 2048, 2304, 2560,
            2880, 3008, 3200, 3360, 3840
        ]
    ) {
        precondition(minimumLogicalWidth > 0, "minimumLogicalWidth must be positive")
        precondition(maximumBackingPixelMultiplier >= 1.0, "maximumBackingPixelMultiplier must be at least 1")
        self.minimumLogicalWidth = minimumLogicalWidth
        self.maximumBackingPixelMultiplier = maximumBackingPixelMultiplier
        self.preserveAspectRatioTolerance = preserveAspectRatioTolerance
        self.preferredLogicalWidths = preferredLogicalWidths
    }
}

public enum HiDPIModeGenerator {
    public static func generateModes(
        for display: DisplayDescriptor,
        policy: HiDPIGenerationPolicy = HiDPIGenerationPolicy()
    ) -> [HiDPIMode] {
        let native = display.nativePixels
        let maximumBackingWidth = Int(Double(native.width) * policy.maximumBackingPixelMultiplier)

        let modes = policy.preferredLogicalWidths.compactMap { logicalWidth -> HiDPIMode? in
            guard logicalWidth >= policy.minimumLogicalWidth else {
                return nil
            }

            let logicalHeight = Int((Double(logicalWidth) / native.aspectRatio).rounded())
            guard logicalHeight > 0 else {
                return nil
            }

            let candidate = HiDPIMode(logicalPoints: PixelSize(width: logicalWidth, height: logicalHeight))
            guard candidate.backingPixels.width <= maximumBackingWidth else {
                return nil
            }

            let candidateAspect = candidate.logicalPoints.aspectRatio
            guard abs(candidateAspect - native.aspectRatio) <= policy.preserveAspectRatioTolerance else {
                return nil
            }

            return candidate
        }

        return Array(Set(modes)).sorted {
            if $0.logicalPoints.width == $1.logicalPoints.width {
                return $0.logicalPoints.height < $1.logicalPoints.height
            }
            return $0.logicalPoints.width < $1.logicalPoints.width
        }
    }

    public static func recommendedMode(
        for display: DisplayDescriptor,
        targetLogicalWidth: Int? = nil,
        policy: HiDPIGenerationPolicy = HiDPIGenerationPolicy()
    ) -> HiDPIMode? {
        let modes = generateModes(for: display, policy: policy)

        if let targetLogicalWidth {
            return modes.min {
                abs($0.logicalPoints.width - targetLogicalWidth) < abs($1.logicalPoints.width - targetLogicalWidth)
            }
        }

        let idealWidth = display.nativePixels.width / 2
        return modes.min {
            abs($0.logicalPoints.width - idealWidth) < abs($1.logicalPoints.width - idealWidth)
        }
    }
}
