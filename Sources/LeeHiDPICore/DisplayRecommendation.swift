import Foundation

public struct RecommendedDisplayConfiguration: Equatable, Sendable {
    public var primary: HiDPIMode
    public var fallback: HiDPIMode?
    public var modesForOverride: [HiDPIMode]
    public var explanation: String

    public init(primary: HiDPIMode, fallback: HiDPIMode?, modesForOverride: [HiDPIMode], explanation: String) {
        self.primary = primary
        self.fallback = fallback
        self.modesForOverride = modesForOverride
        self.explanation = explanation
    }
}

public enum DisplayRecommendationEngine {
    public static func isRecommendedModeActive(for display: DisplayDescriptor) -> Bool {
        guard let recommendation = recommendedConfiguration(for: display),
              let logicalPoints = display.logicalPoints else {
            return false
        }

        return logicalPoints == recommendation.primary.logicalPoints
            && display.nativePixels == recommendation.primary.backingPixels
    }

    public static func recommendedConfiguration(for display: DisplayDescriptor) -> RecommendedDisplayConfiguration? {
        let native = display.nativePixels
        let aspect = native.aspectRatio
        let isWide16By9 = abs(aspect - (16.0 / 9.0)) <= 0.03
        let isTwoKClass = native.width >= 1900 && native.width <= 4300
            && native.height >= 1000 && native.height <= 2400

        if isWide16By9 && isTwoKClass {
            let primary = HiDPIMode(logicalPoints: PixelSize(width: 1920, height: 1080))
            let fallback = HiDPIMode(logicalPoints: PixelSize(width: 2048, height: 1152))
            return RecommendedDisplayConfiguration(
                primary: primary,
                fallback: fallback,
                modesForOverride: [primary, fallback],
                explanation: "24 寸 2K/QHD 外接屏推荐使用 1920x1080 的界面空间，同时用 3840x2160 做 2x 渲染；如果想要更多桌面空间，再切到 2048x1152 HiDPI。"
            )
        }

        guard let primary = HiDPIModeGenerator.recommendedMode(for: display) else {
            return nil
        }

        return RecommendedDisplayConfiguration(
            primary: primary,
            fallback: nil,
            modesForOverride: [primary],
            explanation: "已按当前显示器原生比例选择最接近原生宽度一半的 HiDPI 模式。"
        )
    }
}
