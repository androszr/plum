import Foundation

/// Sizes, budgets and part names read from `docs/asset-brief.md`. The numbers are not copied here.
struct BriefSpec: Sendable {
    var name: String
    var dimensions: (w: Double, d: Double, h: Double)?
    var pixels: (w: Int, h: Int)?
    var panels: Int
    var polyBudget: Int?
    var parts: [String]
    var format: String
    /// True when the section says `Status: stand-in only`: no model file yet.
    var pending = false
    var sourced: Bool
    /// True when the section says `Status: external ...`: made outside the generator, shipped in `Characters/`.
    var external = false

    var isSignage: Bool { dimensions == nil }

    static func load() throws -> [String: BriefSpec] {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        let text = try String(contentsOf: url.appendingPathComponent("docs/asset-brief.md"), encoding: .utf8)
        return try parse(text)
    }

    static func modelsDirectory() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("App/Resources/Models")
    }

    static func charactersDirectory() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("App/Resources/Characters")
    }

    static func parse(_ text: String) throws -> [String: BriefSpec] {
        var specs: [String: BriefSpec] = [:]
        let chunks = text.components(separatedBy: "\n### ").dropFirst()
        let dimPattern = try NSRegularExpression(
            pattern: #"Dimensions:\s*(?:(\d+)\s+posters,\s*)?(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)(?:\s*x\s*(\d+(?:\.\d+)?))?\s*(m|px)"#,
            options: [.caseInsensitive])
        for chunk in chunks {
            let name = chunk.prefix { $0 != "\n" }.trimmingCharacters(in: .whitespaces)
            let dimLine = try value(chunk, "Dimensions:", name)
            let search = "Dimensions: " + dimLine
            let range = NSRange(search.startIndex..., in: search)
            guard let match = dimPattern.firstMatch(in: search, range: range) else {
                throw ParseError("\(name): dimensions \(dimLine)")
            }
            func group(_ i: Int) -> String? {
                let r = match.range(at: i)
                guard r.location != NSNotFound, let swift = Range(r, in: search) else { return nil }
                return String(search[swift])
            }
            let panels = Int(group(1) ?? "") ?? 1
            let unit = (group(5) ?? "").lowercased()
            var dimensions: (w: Double, d: Double, h: Double)?
            var pixels: (w: Int, h: Int)?
            if unit == "m" {
                guard let a = Double(group(2) ?? ""), let b = Double(group(3) ?? ""), let c = Double(group(4) ?? "") else {
                    throw ParseError("\(name): model dimensions need three numbers")
                }
                dimensions = (a, b, c)
            } else {
                let width = Int(Double(group(2) ?? "") ?? 0) * panels
                let heightNumber = group(4) ?? group(3) ?? "0"
                pixels = (width, Int(Double(heightNumber) ?? 0))
            }
            let budgetLine = try value(chunk, "Poly budget:", name)
            let budget: Int?
            if budgetLine.lowercased().contains("not applicable") {
                budget = nil
            } else if let digits = budgetLine.firstMatch(of: /[0-9]+/) {
                budget = Int(digits.output)
            } else {
                budget = nil
            }
            if unit == "m", budget == nil { throw ParseError("\(name): missing poly budget") }
            let partsLine = try value(chunk, "Parts:", name)
            let status = try? value(chunk, "Status:", name)
            specs[name] = BriefSpec(
                name: name,
                dimensions: dimensions,
                pixels: pixels,
                panels: panels,
                polyBudget: budget,
                parts: shapedParts(name, partNames(partsLine)),
                format: try value(chunk, "Format:", name),
                pending: status?.contains("stand-in only") ?? false,
                sourced: sourced(chunk),
                external: status?.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("external") ?? false)
        }
        return specs
    }

    /// True when the section has a `Source:` line that is not `generated`.
    static func sourced(_ body: String) -> Bool {
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) where line.hasPrefix("Source:") {
            let text = line.dropFirst("Source:".count).trimmingCharacters(in: .whitespaces)
            return !text.isEmpty && text.lowercased() != "generated"
        }
        return false
    }

    private static func value(_ body: String, _ label: String, _ section: String) throws -> String {
        for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix(label) {
                return line.split(separator: ":", maxSplits: 1).dropFirst().joined(separator: ":")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        throw ParseError("\(section): missing \(label)")
    }

    /// The three shelf assets carry a packet, a can and a bottle at every spot (the gondola on
    /// both sides). Mirrors `shaped_parts` in `Tools/assetgen/assetgen/brief.py`.
    static func shapedParts(_ name: String, _ parts: [String]) -> [String] {
        guard ["gondola_shelf", "wall_shelf", "end_cap"].contains(name) else { return parts }
        let stems = name == "gondola_shelf" ? ["product", "product_back"] : ["product"]
        var out: [String] = []
        for part in parts {
            guard let match = part.wholeMatch(of: /product_(\d+)_(\d+)/) else {
                out.append(part)
                continue
            }
            for stem in stems {
                for shape in ["packet", "can", "bottle"] { out.append("\(stem)_\(match.1)_\(match.2)_\(shape)") }
            }
        }
        return out
    }

    /// Concrete prim names. Ranges expand; prose does not. Mirrors `Tools/assetgen/assetgen/brief.py`.
    static func partNames(_ partsLine: String) -> [String] {
        let text = String(partsLine.split(separator: ".", maxSplits: 1).first ?? "")
        var shelves: [Int] = []
        if let match = text.firstMatch(of: /shelf_(\d+)-(\d+)/) {
            let a = Int(match.1) ?? 0
            let b = Int(match.2) ?? 0
            shelves = Array(a...b)
        }
        var hoops: [Int] = []
        if let match = text.firstMatch(of: /hoop_(\d+)-(\d+)/) {
            let a = Int(match.1) ?? 0
            let b = Int(match.2) ?? 0
            hoops = Array(a...b)
        }
        var names: [String] = []
        var seen = Set<String>()
        func add(_ found: [String]) {
            for name in found where !seen.contains(name) {
                seen.insert(name)
                names.append(name)
            }
        }
        func take(_ segment: String) {
            let segment = segment.trimmingCharacters(in: .whitespaces)
            if segment.isEmpty { return }
            let head: String
            let paren: String
            if let open = segment.firstIndex(of: "("), let close = segment.lastIndex(of: ")"), open < close {
                head = String(segment[..<open]).trimmingCharacters(in: .whitespaces)
                paren = String(segment[segment.index(after: open)..<close]).trimmingCharacters(in: .whitespaces)
            } else {
                head = segment
                paren = ""
            }
            let first = head.split(separator: " ").first.map(String.init) ?? ""
            if head.range(of: #"^product rows\b"#, options: .regularExpression) != nil {
                let count = atLeast(paren) ?? atLeast(head) ?? 16
                let rows = shelves.isEmpty ? [0] : shelves
                let per = max(1, (count + rows.count - 1) / rows.count)
                add(rows.flatMap { shelf in (0..<per).map { "product_\(shelf)_\($0)" } })
            } else {
                let expanded = expandRange(first)
                let prose = head.split(separator: " ").count > 1 && !first.contains("_") && first.range(of: #"\d+-\d+"#, options: .regularExpression) == nil
                if let expanded, !first.contains("<"), !prose { add(expanded) }
                for token in matches(head, #"[a-z][a-z0-9_]*_<[^>]+>(?:_[a-z0-9_<>]+)*"#) {
                    add(expandTemplate(token, atLeast(head) ?? atLeast(paren), shelves, hoops))
                }
            }
            if paren.isEmpty { return }
            for piece in splitCommas(paren) {
                let piece = piece.trimmingCharacters(in: .whitespaces)
                let templates = matches(piece, #"[a-z][a-z0-9_]*_<[^>]+>(?:_[a-z0-9_<>]+)*"#)
                if !templates.isEmpty {
                    let count = atLeast(piece) ?? atLeast(paren)
                    for token in templates { add(expandTemplate(token, count, shelves, hoops)) }
                    continue
                }
                let lead = piece.split(separator: " ").first.map(String.init) ?? ""
                if let expanded = expandRange(lead), lead.contains("_") || lead.range(of: #"\d+-\d+"#, options: .regularExpression) != nil {
                    add(expanded)
                }
            }
        }
        for segment in splitCommas(text) { take(segment) }
        return names
    }

    private static func splitCommas(_ text: String) -> [String] {
        var parts: [String] = []
        var buf = ""
        var depth = 0
        for ch in text {
            if ch == "(" { depth += 1 }
            if ch == ")" { depth = max(0, depth - 1) }
            if ch == "," && depth == 0 {
                parts.append(buf)
                buf = ""
            } else {
                buf.append(ch)
            }
        }
        if !buf.isEmpty { parts.append(buf) }
        return parts
    }

    private static func expandRange(_ token: String) -> [String]? {
        if let match = token.wholeMatch(of: /([a-z][a-z0-9_]*?)_(\d+)-(\d+)/) {
            let stem = String(match.1)
            let a = Int(match.2) ?? 0
            let b = Int(match.3) ?? 0
            return (a...b).map { "\(stem)_\($0)" }
        }
        if token.wholeMatch(of: /[a-z][a-z0-9_]*/) != nil { return [token] }
        return nil
    }

    private static func atLeast(_ text: String) -> Int? {
        guard let match = text.firstMatch(of: /at least (\d+)/) else { return nil }
        return Int(match.1)
    }

    private static func shelfRows(_ stem: String, _ count: Int?, _ shelves: [Int]) -> [String] {
        let rows = shelves.isEmpty ? [0] : shelves
        let per = max(1, ((count ?? rows.count) + rows.count - 1) / rows.count)
        return rows.flatMap { shelf in (0..<per).map { "\(stem)_\(shelf)_\($0)" } }
    }

    private static func expandTemplate(_ token: String, _ count: Int?, _ shelves: [Int], _ hoops: [Int]) -> [String] {
        if let match = token.wholeMatch(of: /([a-z][a-z0-9_]*)_<shelf>_<i>/) {
            return shelfRows(String(match.1), count, shelves)
        }
        if let match = token.wholeMatch(of: /([a-z][a-z0-9_]*)_<shelf>_<facing>/) {
            return shelfRows(String(match.1), count, shelves)
        }
        if let match = token.wholeMatch(of: /hoop_<i>_([a-z0-9_]+)/) {
            let tail = String(match.1)
            return hoops.map { "hoop_\($0)_\(tail)" }
        }
        if let match = token.wholeMatch(of: /([a-z][a-z0-9_]*)_<i>/) {
            let stem = String(match.1)
            return (0..<(count ?? 1)).map { "\(stem)_\($0)" }
        }
        return []
    }

    private static func matches(_ text: String, _ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }
}

private struct ParseError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
}
