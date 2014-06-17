import Foundation

@objc protocol TagCreateViewDelegate {
    func tagCreationWasSubmitted()
    func tagCreationDidSucceed()
    func tagCreationDidFail()
}