import Foundation

// TODO: can we add this to the same file as TagView?
@objc protocol TagViewDelegate {
    func tagAcknowledgementWasSubmitted()
    func tagAcknowledgementDidSucceed(String)
    func tagAcknowledgementDidFail()
}
