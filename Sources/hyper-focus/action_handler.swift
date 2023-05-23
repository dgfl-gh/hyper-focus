import Cocoa
import Foundation

// TODO: is enum really the right thing to do here? Unsure :)
//       best way I could find to group together related functions

// once a "action" (window change, etc) is detected and normalized, it's passed to the ActionHandler to determine
// exactly how to handle it.
enum ActionHandler {
    static func handleAction(_ data: SwitchingActivity) {
        log("handling action: \(data)")

        if appAction(data) { return }
        if browserAction(data) { return }
    }

    static func extractHost(_ url: String) -> String? {
        let url = URL(string: url)
        return url?.host
    }

    static func appAction(_ data: SwitchingActivity) -> Bool {
        if match(data.app, data.configuration.block_apps) {
            log("app is in block_apps, hiding application to prevent usage")
            // TODO: sometimes this hide method does not work
            NSWorkspace.shared.frontmostApplication!.hide()
            return true
        }

        return false
    }

    static func browserAction(_ data: SwitchingActivity) -> Bool {
        guard let url = data.url else {
            log("url is empty, not doing anything")
            return false
        }

        guard let host = extractHost(url) else {
            error("no host, not a valid url, skipping ")
            return false
        }

        let blockHosts = data.configuration.block_hosts

        if match(host, blockHosts) {
            error("blocked host, redirecting browser to block page")
            blockTab(data.activeTab)
            return true
        }

        debug("checking urls for any blocked matches")

        let blockUrls = data.configuration.block_urls
        // the urls in the config are expected to have less params, so they are considered the subset
        if blockUrls.count > 0 && blockUrls.contains(where: { isSubsetOfUrl(supersetUrlString: url, subsetUrlString: $0) }) {
            error("blocked url, redirecting browser to block page")
            blockTab(data.activeTab)
            return true
        }

        return false
    }
    
    static func match(_ str: String, _ patternArray: [String]) -> Bool {
        if patternArray.count == 0 {
            return false
        }

        // split array into regexps and non-regexps
        // regex strings should start with `//`, so then strip it from the beginning of each string
        let nonRegexArray: [String] = patternArray.filter { !$0.starts(with: "//") }
        let regexArray: [String] = patternArray.filter{ $0.starts(with: "//")}.map{String($0.dropFirst(2))}
        
        if nonRegexArray.contains(str) {
            debug("String \(str) matched non-regexp")
            return true
        }
        if let matchedPattern = regexArray.first(where: { pattern in
            let regex = try! NSRegularExpression(pattern: pattern)
            return regex.firstMatch(in: str, range: NSRange(location: 0, length: str.utf16.count)) != nil
        }) {
            debug("String \(str) matched pattern: \(matchedPattern)")
            return true
        }

        return false
    }

    static func isSubsetOfUrl(supersetUrlString: String, subsetUrlString: String) -> Bool {
        // TODO: there could be a case where this is no query string, but anchor references; what should we do there?
        //      anchors can be significant, but only sometimes

        // if the urls are equal, we can consider them a subset
        if supersetUrlString == subsetUrlString {
            return true
        }

        let optionalSupersetUrl = URLComponents(string: supersetUrlString)
        let optionalSubsetUrl = URLComponents(string: subsetUrlString)

        guard let supersetUrl = optionalSupersetUrl, let subsetUrl = optionalSubsetUrl else {
            error("invalid url (\(supersetUrlString)), skipping \(String(describing: optionalSupersetUrl)) \(String(describing: optionalSubsetUrl))")
            return false
        }

        // TODO: too big, should be a separate method!
        var queryIsSubset = true
        if let supersetQueryItems = supersetUrl.queryItems, let subsetQueryItems = subsetUrl.queryItems {
            subsetQueryItems.forEach { subsetQueryItem in
                if !supersetQueryItems.contains(subsetQueryItem) {
                    queryIsSubset = false
                }
            }
        } else {
            queryIsSubset = false
        }

        return queryIsSubset &&
            supersetUrl.host == subsetUrl.host &&
            supersetUrl.path == subsetUrl.path
    }

    static func blockTab(_ activeTab: BrowserTab?) {
        // TODO: allow redirect to be configured
        let redirectUrl: String? = "about:blank"

        // TODO: I don't know how to more elegantly unwrap the enum here...
        switch activeTab {
        case let .chrome(tab):
            tab.setURL!(redirectUrl)
        case let .safari(tab):
            tab.setURL!(redirectUrl)
        // TODO: firefox?
        case .none:
            break
        }
    }
}
