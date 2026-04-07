import CoreGraphics
import Foundation

public enum PanelPlacementCalculator {
    public static func origin(
        forStatusButtonFrame buttonFrame: CGRect,
        panelSize: CGSize,
        visibleFrame: CGRect,
        horizontalPadding: CGFloat = 12,
        verticalPadding: CGFloat = 12,
        gapBelowStatusItem: CGFloat = 8
    ) -> CGPoint {
        let centeredX = buttonFrame.midX - panelSize.width / 2
        let x = min(
            max(centeredX, visibleFrame.minX + horizontalPadding),
            visibleFrame.maxX - panelSize.width - horizontalPadding
        )

        let preferredY = buttonFrame.minY - panelSize.height - gapBelowStatusItem
        let y = max(preferredY, visibleFrame.minY + verticalPadding)

        return CGPoint(x: x, y: y)
    }
}
