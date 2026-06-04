import ApplicationServices
import Foundation

public struct RuntimeDisplayMode: Equatable, Hashable, Sendable, CustomStringConvertible {
    public var logicalPoints: PixelSize
    public var backingPixels: PixelSize
    public var refreshRate: Double
    public var isHiDPI: Bool

    public init(logicalPoints: PixelSize, backingPixels: PixelSize, refreshRate: Double, isHiDPI: Bool) {
        self.logicalPoints = logicalPoints
        self.backingPixels = backingPixels
        self.refreshRate = refreshRate
        self.isHiDPI = isHiDPI
    }

    public var description: String {
        let rate = refreshRate > 0 ? " @ \(Int(refreshRate.rounded()))Hz" : ""
        let kind = isHiDPI ? "HiDPI" : "标准"
        return "\(logicalPoints) \(kind)（\(backingPixels) 渲染\(rate)）"
    }
}

public enum DisplayModeControlError: Error, Equatable, LocalizedError {
    case modeNotFound
    case cannotApplyMode(CGError)

    public var errorDescription: String? {
        switch self {
        case .modeNotFound:
            "系统当前没有暴露这个显示模式。"
        case let .cannotApplyMode(error):
            "无法切换显示模式：\(error)"
        }
    }
}

public struct CoreGraphicsDisplayModeController {
    public init() {}

    public func availableModes(for display: DisplayDescriptor) -> [RuntimeDisplayMode] {
        guard let modes = CGDisplayCopyAllDisplayModes(
            display.displayID,
            [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary
        ) as? [CGDisplayMode] else {
            return []
        }

        let runtimeModes = modes.map(Self.runtimeMode(from:))
        return Array(Set(runtimeModes)).sorted {
            if $0.logicalPoints.width != $1.logicalPoints.width {
                return $0.logicalPoints.width < $1.logicalPoints.width
            }
            if $0.logicalPoints.height != $1.logicalPoints.height {
                return $0.logicalPoints.height < $1.logicalPoints.height
            }
            if $0.isHiDPI != $1.isHiDPI {
                return $0.isHiDPI && !$1.isHiDPI
            }
            return $0.refreshRate < $1.refreshRate
        }
    }

    public func apply(_ target: RuntimeDisplayMode, to display: DisplayDescriptor) throws {
        guard let modes = CGDisplayCopyAllDisplayModes(
            display.displayID,
            [kCGDisplayShowDuplicateLowResolutionModes: true] as CFDictionary
        ) as? [CGDisplayMode] else {
            throw DisplayModeControlError.modeNotFound
        }

        guard let mode = modes.first(where: { Self.runtimeMode(from: $0) == target }) else {
            throw DisplayModeControlError.modeNotFound
        }

        let result = CGDisplaySetDisplayMode(display.displayID, mode, nil)
        guard result == .success else {
            throw DisplayModeControlError.cannotApplyMode(result)
        }
    }

    private static func runtimeMode(from mode: CGDisplayMode) -> RuntimeDisplayMode {
        let logical = PixelSize(width: max(mode.width, 1), height: max(mode.height, 1))
        let backing = PixelSize(width: max(mode.pixelWidth, mode.width), height: max(mode.pixelHeight, mode.height))
        let isHiDPI = backing.width >= logical.width * 2 && backing.height >= logical.height * 2

        return RuntimeDisplayMode(
            logicalPoints: logical,
            backingPixels: backing,
            refreshRate: mode.refreshRate,
            isHiDPI: isHiDPI
        )
    }
}
