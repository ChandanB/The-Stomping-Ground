//
//  Extensions.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 12/16/22.
//

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
