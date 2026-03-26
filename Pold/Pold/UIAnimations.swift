import SwiftUI

enum UIAnimations {
    static let history = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let detail = Animation.easeInOut(duration: 0.18)
    static let hover = Animation.easeOut(duration: 0.12)
}
