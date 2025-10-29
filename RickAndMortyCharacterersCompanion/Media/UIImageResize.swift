
import UIKit

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage? {
        let maxDim = max(size.width, size.height)
        guard maxDim > maxSide else { return self }
        let scale = maxSide / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
