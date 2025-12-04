import Foundation

final class NumberFormatService {
    static let shared = NumberFormatService()

    private let numberFormatter: NumberFormatter
    private let decimalFormatter: NumberFormatter

    private init() {
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0

        decimalFormatter = NumberFormatter()
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.maximumFractionDigits = 1
        decimalFormatter.minimumFractionDigits = 1
    }

    func format(_ value: Double) -> String {
        if value < 1000 {
            return numberFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        } else if value < 1_000_000 {
            let k = value / 1000
            if k >= 100 {
                return "\(Int(k))K"
            }
            return "\(decimalFormatter.string(from: NSNumber(value: k)) ?? String(format: "%.1f", k))K"
        } else if value < 1_000_000_000 {
            let m = value / 1_000_000
            if m >= 100 {
                return "\(Int(m))M"
            }
            return "\(decimalFormatter.string(from: NSNumber(value: m)) ?? String(format: "%.1f", m))M"
        } else if value < 1_000_000_000_000 {
            let b = value / 1_000_000_000
            if b >= 100 {
                return "\(Int(b))B"
            }
            return "\(decimalFormatter.string(from: NSNumber(value: b)) ?? String(format: "%.1f", b))B"
        } else if value < 1_000_000_000_000_000 {
            let t = value / 1_000_000_000_000
            if t >= 100 {
                return "\(Int(t))T"
            }
            return "\(decimalFormatter.string(from: NSNumber(value: t)) ?? String(format: "%.1f", t))T"
        } else {
            let q = value / 1_000_000_000_000_000
            if q >= 100 {
                return "\(Int(q))Q"
            }
            return "\(decimalFormatter.string(from: NSNumber(value: q)) ?? String(format: "%.1f", q))Q"
        }
    }

    func formatCoins(_ value: Double) -> String {
        format(value)
    }

    func formatTaps(_ value: Double) -> String {
        format(value)
    }

    func formatMultiplier(_ value: Double) -> String {
        if value < 10 {
            return String(format: "%.2fx", value)
        } else if value < 100 {
            return String(format: "%.1fx", value)
        } else {
            return "\(format(value))x"
        }
    }

    func formatPercent(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)

        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            let secs = totalSeconds % 60
            return String(format: "%d:%02d", minutes, secs)
        } else {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return String(format: "%d:%02d:%02d", hours, minutes, totalSeconds % 60)
        }
    }

    func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)

        if totalSeconds < 60 {
            return "\(totalSeconds) seconds"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }

    func formatRank(_ position: Int) -> String {
        let suffix: String
        let lastTwo = position % 100
        let lastOne = position % 10

        if lastTwo >= 11 && lastTwo <= 13 {
            suffix = "th"
        } else {
            switch lastOne {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }

        return "#\(format(Double(position)))\(suffix)"
    }
}
