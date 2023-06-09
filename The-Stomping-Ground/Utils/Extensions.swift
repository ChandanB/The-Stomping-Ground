//
//  Extensions.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/16/22.
//

import Foundation
import SwiftUI


/// Provides fast rendering of responsive images
extension Double {
    var responsiveW: Double { return (UIScreen.main.bounds.size.width * self) / 100 }
    var responsiveH: Double { return (UIScreen.main.bounds.size.height * self) / 100 }
}

/// Enumerate through save errors
enum SaveError: Error {
    case unfoundedPath(desc: String)
    case uniqueIssue(desc: String)
    case setIssue(desc: String)
    case noDocument(desc: String)
}

/// Enumerate through data import errors
enum GetError: Error {
    case unfoundedDocument(desc: String)
    case noDocument(desc: String)
    case loadIssue(desc: String)
}

struct RootPresentationModeKey: EnvironmentKey {
    static let defaultValue: Binding<RootPresentationMode> = .constant(RootPresentationMode())
}

extension EnvironmentValues {
    var rootPresentationMode: Binding<RootPresentationMode> {
        get { return self[RootPresentationModeKey.self] }
        set { self[RootPresentationModeKey.self] = newValue }
    }
}

typealias RootPresentationMode = Bool

extension RootPresentationMode {
    
    public mutating func dismiss() {
        self.toggle()
    }
}

// Debouncer helper class
class Debouncer {
    private let delay: DispatchTimeInterval
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?
    
    init(delay: DispatchTimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.delay = delay
        self.queue = queue
    }
    
    func run(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}


extension String {
    
    func hasUppercasedCharacters() -> Bool {
        return stringFulfillsRegex(regex:  ".*[A-Z]+.*")
    }
    
    func hasSpecialCharacters() -> Bool {
        return stringFulfillsRegex(regex: ".*[^A-Za-z0-9].*")
    }
    
    private func stringFulfillsRegex(regex: String) -> Bool {
        let texttest = NSPredicate(format: "SELF MATCHES %@", regex)
        guard texttest.evaluate(with: self) else {
            return false
        }
        return true
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}


extension NSAttributedString {
    func resizedImages(maxSize: CGSize) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(attributedString: self)
        
        self.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: self.length), options: []) { (value, range, _) in
            if let attachment = value as? NSTextAttachment {
                let imageSize = attachment.image?.size ?? .zero
                let aspectRatio = imageSize.width / imageSize.height
                
                let newWidth = min(maxSize.width, imageSize.width)
                let newHeight = newWidth / aspectRatio
                
                let newImageSize = CGSize(width: newWidth, height: newHeight)
                let newImage = attachment.image?.resized(to: newImageSize)
                
                let newAttachment = NSTextAttachment()
                newAttachment.image = newImage
                
                let newAttributedString = NSAttributedString(attachment: newAttachment)
                mutableAttributedString.replaceCharacters(in: range, with: newAttributedString)
            }
        }
        
        return NSAttributedString(attributedString: mutableAttributedString)
    }
}


extension String {
    
    func htmlToNSAttributedString() -> NSAttributedString? {
        do {
            let data = Data(utf8)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributedString
        } catch {
            print("Error converting HTML to NSAttributedString: \(error)")
            return nil
        }
    }
    
    func stripHTML() -> String {
        let range = NSRange(location: 0, length: utf16.count)
        guard let regex = try? NSRegularExpression(pattern: "<.*?>", options: []) else {
            return self
        }
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func shortPreview(maxLength: Int, afterTag tag: String = "<p>") -> String {
        let strippedText = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let trimmedText = strippedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let tagRange = trimmedText.range(of: tag) {
            let startIndex = trimmedText.index(tagRange.upperBound, offsetBy: 0)
            let endIndex = trimmedText.index(startIndex, offsetBy: min(maxLength, trimmedText.distance(from: startIndex, to: trimmedText.endIndex)), limitedBy: trimmedText.endIndex) ?? trimmedText.endIndex
            return String(trimmedText[startIndex..<endIndex] + "... Read More")
        } else {
            let endIndex = trimmedText.index(trimmedText.startIndex, offsetBy: min(maxLength, trimmedText.count), limitedBy: trimmedText.endIndex) ?? trimmedText.endIndex
            return String(trimmedText[trimmedText.startIndex..<endIndex] + "... Read More")
        }
    }
}


extension Array where Element: Equatable {
    
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
    
}

struct CustomFontText: View {
    var text: String
    var size: CGFloat = FontConstants.regularBodySize

    var body: some View {
        Text(text)
            .customFont(name: FontConstants.regular, size: size)
    }
}

struct CustomFontModifier: ViewModifier {
    let fontName: String
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(Font.custom(fontName, size: size))
    }
}

extension View {
    func customFont(name: String, size: CGFloat) -> some View {
        self.modifier(CustomFontModifier(fontName: name, size: size))
    }
}

struct AppTheme {
    static func applyFont() {
        let fontDescriptor = UIFontDescriptor(name: FontConstants.regular, size: FontConstants.regularBodySize)
        let font = UIFont(descriptor: fontDescriptor, size: 17)

        UIBarButtonItem.appearance().setTitleTextAttributes([.font: font], for: .normal)
        UINavigationBar.appearance().titleTextAttributes = [.font: font]
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: font]

        UISegmentedControl.appearance().setTitleTextAttributes([.font: font], for: .normal)
        UITextView.appearance().font = font
        UITextField.appearance().defaultTextAttributes = [.font: font]

        UIButton.appearance().titleLabel?.font = font
        UILabel.appearance().font = font
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, apply: (Self) -> Content, `else`: (Self) -> Content) -> some View {
        if condition {
            apply(self)
        } else {
            `else`(self)
        }
    }
}

extension View {
    func conditionalHeadline(_ text: Text, isBold: Bool) -> some View {
        Group {
            if isBold {
                text.blackHeadline()
            } else {
                text.regularHeadline()
            }
        }
    }
}
