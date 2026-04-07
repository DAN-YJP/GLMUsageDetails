import SwiftUI
import Charts

// MARK: - Normalized data points

/// Unified per-day model. Both charts reference the same array,
/// guaranteeing X-axis alignment. Date is normalized to startOfDay.
private struct DailyUsagePoint: Identifiable {
    let id = UUID()
    let date: Date          // normalized to 00:00:00 local time
    let dayLabel: String    // "03-31"
    let weekdayLabel: String // "Mon 03/31"
    let calls: Int
    let tokens: Int
    let cost: Double
}

/// Per-hour model for 5h/1d windows.
private struct HourlyUsagePoint: Identifiable {
    let id = UUID()
    let date: Date          // normalized to start of hour
    let hourLabel: String   // "14:00"
    let detailLabel: String // "04/07 14:00"
    let calls: Int
    let tokens: Int
    let cost: Double
}

public struct WeeklyDetailView: View {
    let snapshot: UsageDetailSnapshot
    let timeWindow: TimeWindow
    let language: AppLanguage
    var onHeightChange: ((CGFloat) -> Void)?

    @State private var selectedPoint: DailyUsagePoint?
    @State private var selectedHourlyPoint: HourlyUsagePoint?
    @State private var showCalls = true
    @State private var showTokens = true

    private let chartColors: [Color] = [.blue, .green, .orange, .purple, .pink, .cyan, .yellow, .mint]
    private let chartHeight: CGFloat = 280

    // ── Pre-computed data (computed once in init) ─────────

    private let isHourly: Bool
    private let dailyPoints: [DailyUsagePoint]
    private let hourlyPoints: [HourlyUsagePoint]
    private let callTicks: [Int]
    private let tokenTicks: [Int]
    private let callYDomain: ClosedRange<Double>
    private let tokenYDomain: ClosedRange<Double>
    private let chartDomain: ClosedRange<Date>

    // ── Static DateFormatters (created once, shared) ──────

    private static let parseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private static let dayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let weekdayLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MM/dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let hourParseFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        return f
    }()

    private static let hourLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let hourDetailFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // ── Init ──────────────────────────────────────────────

    public init(snapshot: UsageDetailSnapshot, timeWindow: TimeWindow = .oneWeek, language: AppLanguage, onHeightChange: ((CGFloat) -> Void)? = nil) {
        self.snapshot = snapshot
        self.timeWindow = timeWindow
        self.language = language
        self.onHeightChange = onHeightChange

        let useHourly = timeWindow == .fiveHour || timeWindow == .oneDay
        self.isHourly = useHourly

        if useHourly {
            // Build hourly points
            let hPoints = snapshot.hourlyBreakdown.compactMap { record -> HourlyUsagePoint? in
                guard let date = Self.hourParseFormatter.date(from: record.hour) else { return nil }
                return HourlyUsagePoint(
                    date: date,
                    hourLabel: Self.hourLabelFormatter.string(from: date),
                    detailLabel: Self.hourDetailFormatter.string(from: date),
                    calls: record.calls,
                    tokens: record.tokens,
                    cost: record.cost
                )
            }.sorted { $0.date < $1.date }
            self.hourlyPoints = hPoints
            self.dailyPoints = []

            let callValues = hPoints.map(\.calls)
            let tokenValues = hPoints.map(\.tokens)
            self.callTicks = Self.niceTicks(for: callValues, desiredCount: 5)
            self.tokenTicks = Self.niceTicks(for: tokenValues, desiredCount: 5)

            self.callYDomain = Self.yDomain(from: self.callTicks)
            self.tokenYDomain = Self.yDomain(from: self.tokenTicks)

            if let minDate = hPoints.map(\.date).min(), let maxDate = hPoints.map(\.date).max() {
                self.chartDomain = minDate.addingTimeInterval(-1800)...maxDate.addingTimeInterval(1800)
            } else {
                let now = Date()
                self.chartDomain = now.addingTimeInterval(-5 * 3600)...now
            }
        } else {
            // Build daily points (existing behavior)
            let points = snapshot.dailyBreakdown.compactMap { record -> DailyUsagePoint? in
                guard let date = Self.parseFormatter.date(from: record.day) else { return nil }
                let normalized = Calendar.current.startOfDay(for: date)
                return DailyUsagePoint(
                    date: normalized,
                    dayLabel: Self.dayLabelFormatter.string(from: normalized),
                    weekdayLabel: Self.weekdayLabelFormatter.string(from: normalized),
                    calls: record.calls,
                    tokens: record.tokens,
                    cost: record.cost
                )
            }.sorted { $0.date < $1.date }
            self.dailyPoints = points
            self.hourlyPoints = []

            let callValues = points.map(\.calls)
            let tokenValues = points.map(\.tokens)
            self.callTicks = Self.niceTicks(for: callValues, desiredCount: 5)
            self.tokenTicks = Self.niceTicks(for: tokenValues, desiredCount: 5)

            self.callYDomain = Self.yDomain(from: self.callTicks)
            self.tokenYDomain = Self.yDomain(from: self.tokenTicks)

            if let minDate = points.map(\.date).min(), let maxDate = points.map(\.date).max() {
                self.chartDomain = minDate.addingTimeInterval(-12 * 3600)...maxDate.addingTimeInterval(12 * 3600)
            } else {
                let now = Date()
                self.chartDomain = now.addingTimeInterval(-7 * 86400)...now
            }
        }
    }

    private static func yDomain(from ticks: [Int]) -> ClosedRange<Double> {
        guard let first = ticks.first, let last = ticks.last, first < last else {
            return 0...1
        }
        return Double(first)...Double(last)
    }

    public var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 16) {
                    detailHeader
                    summarySection
                    dailyChartSection
                    productBreakdownSection
                }
                .padding(20)
                .background(
                    GeometryReader { inner in
                        Color.clear
                            .preference(key: ContentHeightKey.self, value: inner.size.height)
                    }
                )
            }
            .onPreferenceChange(ContentHeightKey.self) { height in
                let padding: CGFloat = 40 // vertical scrollbar + window chrome margin
                let newHeight = height + padding
                let screenH = NSScreen.main?.visibleFrame.height ?? 900
                let clamped = min(newHeight, screenH - 80)
                onHeightChange?(clamped)
            }
            .frame(minWidth: timeWindow == .oneMonth ? 700 : 620, minHeight: geo.size.height)
        }
        .frame(minWidth: timeWindow == .oneMonth ? 700 : 620, idealHeight: 720, maxHeight: .infinity)
    }

    // MARK: - Header

    private var detailHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: headerIcon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(AppStrings.detailTitle(for: timeWindow, language: language))
                .font(.title2.weight(.semibold))
            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var headerIcon: String {
        switch timeWindow {
        case .fiveHour: return "clock"
        case .oneDay: return "clock.fill"
        case .oneWeek: return "calendar"
        case .oneMonth: return "calendar.badge.clock"
        }
    }

    // MARK: - Section 1: Summary

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statTile(
                    title: AppStrings.callCount(language: language),
                    value: QuotaFormatter.callCount(snapshot.totalCalls),
                    icon: "arrow.up.arrow.down.circle",
                    color: .blue
                )
                tokenStatTile
                statTile(
                    title: AppStrings.cost(language: language),
                    value: QuotaFormatter.cost(snapshot.totalCost),
                    icon: "yensign.circle",
                    color: .orange
                )
            }

            if snapshot.tokenBreakdown != .zero {
                tokenBreakdownRow
            }
        }
    }

    private var tokenStatTile: some View {
        statTile(
            title: AppStrings.tokenUsage(language: language),
            value: QuotaFormatter.tokenCount(snapshot.totalTokens),
            icon: "number.circle",
            color: .green
        )
    }

    private var tokenBreakdownRow: some View {
        HStack(spacing: 12) {
            tokenBreakdownChip(
                label: AppStrings.inputTokens(language: language),
                value: snapshot.tokenBreakdown.inputTokens,
                color: .teal
            )
            tokenBreakdownChip(
                label: AppStrings.outputTokens(language: language),
                value: snapshot.tokenBreakdown.outputTokens,
                color: .indigo
            )
            tokenBreakdownChip(
                label: AppStrings.cacheHitTokens(language: language),
                value: snapshot.tokenBreakdown.cacheHitTokens,
                color: .mint
            )
        }
    }

    private func tokenBreakdownChip(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(QuotaFormatter.tokenCount(value))
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    private func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.callout.weight(.medium))
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    // MARK: - Section 2: Daily Trend Chart (dual Chart, external axes)

    private var dailyChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(isHourly ? AppStrings.hourlyCallsAndTokens(language: language) : AppStrings.dailyCallsAndTokens(language: language))
                    .font(.headline.weight(.semibold))
                Spacer()
                chartLegend
            }

            if isHourly && hourlyPoints.isEmpty || !isHourly && dailyPoints.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                // ── Dual Chart ZStack ──────────────────────
                // Both charts have ALL native axis labels hidden.
                // Axis labels are drawn in chartOverlay using proxy.position(for:)
                // so they align precisely with grid lines.
                // Both charts share the same frame and X domain → perfect X alignment.
                ZStack {
                    if isHourly {
                        hourlyChartStack
                    } else {
                        dailyChartStack
                    }
                }
                .frame(height: chartHeight)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    // MARK: - Legend

    private var chartLegend: some View {
        HStack(spacing: 20) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showCalls.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(showCalls ? .blue : .blue.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(AppStrings.callCount(language: language))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(showCalls ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showTokens.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(showTokens ? .green : .green.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text(AppStrings.tokenUsage(language: language))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(showTokens ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .padding(.top, 6)
    }

    // MARK: - Tooltip

    private func dailyTooltipOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        Group {
            if let point = selectedPoint {
                if let pos = proxy.position(for: (x: point.date, y: Double(point.tokens))) {
                    let tooltipWidth: CGFloat = 210
                    let clampedX = min(max(pos.x, tooltipWidth / 2 + 4), geometry.size.width - tooltipWidth / 2 - 4)
                    let tooltipY: CGFloat = 44

                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.12))
                            )
                            .frame(width: tooltipWidth, height: 72)
                            .overlay(
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.weekdayLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 16) {
                                        if showCalls {
                                            Label {
                                                Text(compactCount(point.calls))
                                                    .font(.caption.monospacedDigit())
                                            } icon: {
                                                Circle().fill(.blue).frame(width: 6, height: 6)
                                            }
                                        }
                                        if showTokens {
                                            Label {
                                                Text(QuotaFormatter.tokenCount(point.tokens))
                                                    .font(.caption.monospacedDigit())
                                            } icon: {
                                                Circle().fill(.green).frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                    Text(QuotaFormatter.cost(point.cost))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                            )
                            .position(x: clampedX, y: tooltipY)
                    }

                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 1, height: geometry.size.height)
                        .position(x: pos.x, y: geometry.size.height / 2)
                }
            }
        }
        .animation(.easeInOut(duration: 0.12), value: selectedPoint?.id)
    }

    private func hourlyTooltipOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        Group {
            if let point = selectedHourlyPoint {
                if let pos = proxy.position(for: (x: point.date, y: Double(point.tokens))) {
                    let tooltipWidth: CGFloat = 210
                    let clampedX = min(max(pos.x, tooltipWidth / 2 + 4), geometry.size.width - tooltipWidth / 2 - 4)
                    let tooltipY: CGFloat = 44

                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.12))
                            )
                            .frame(width: tooltipWidth, height: 72)
                            .overlay(
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(point.detailLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 16) {
                                        if showCalls {
                                            Label {
                                                Text(compactCount(point.calls))
                                                    .font(.caption.monospacedDigit())
                                            } icon: {
                                                Circle().fill(.blue).frame(width: 6, height: 6)
                                            }
                                        }
                                        if showTokens {
                                            Label {
                                                Text(QuotaFormatter.tokenCount(point.tokens))
                                                    .font(.caption.monospacedDigit())
                                            } icon: {
                                                Circle().fill(.green).frame(width: 6, height: 6)
                                            }
                                        }
                                    }
                                    Text(QuotaFormatter.cost(point.cost))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                            )
                            .position(x: clampedX, y: tooltipY)
                    }

                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 1, height: geometry.size.height)
                        .position(x: pos.x, y: geometry.size.height / 2)
                }
            }
        }
        .animation(.easeInOut(duration: 0.12), value: selectedHourlyPoint?.id)
    }

    // MARK: - Chart Stacks

    private var dailyChartStack: some View {
        ZStack {
            // Bottom layer: Tokens chart (green)
            Chart(dailyPoints) { point in
                if showTokens {
                    AreaMark(
                        x: .value("Day", point.date),
                        y: .value("Tokens", point.tokens)
                    )
                    .foregroundStyle(.green.opacity(0.08))
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Tokens", point.tokens)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle())
                    .symbolSize(50)
                    .interpolationMethod(.linear)
                }
            }
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: tokenYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: 86400)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartYAxis {
                AxisMarks(values: tokenTicks.map { Double($0) }) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.15, dash: [2, 2]))
                }
            }
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        ForEach(tokenTicks, id: \.self) { tick in
                            if let pos = proxy.position(
                                for: (x: chartDomain.upperBound, y: Double(tick))
                            ) {
                                Text(QuotaFormatter.tokenCount(tick))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.green)
                                    .position(x: geometry.size.width - 4, y: pos.y)
                            }
                        }
                        ForEach(dailyPoints) { point in
                            if let pos = proxy.position(
                                for: (x: point.date, y: tokenYDomain.lowerBound)
                            ) {
                                Text(point.dayLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .position(x: pos.x, y: geometry.size.height - 6)
                            }
                        }
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    guard let date: Date = proxy.value(atX: location.x) else { return }
                                    selectedPoint = dailyPoints.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                case .ended:
                                    selectedPoint = nil
                                }
                            }
                            .overlay(dailyTooltipOverlay(proxy: proxy, geometry: geometry))
                    }
                }
            }

            // Top layer: Calls chart (blue)
            Chart(dailyPoints) { point in
                if showCalls {
                    AreaMark(
                        x: .value("Day", point.date),
                        y: .value("Calls", point.calls)
                    )
                    .foregroundStyle(.blue.opacity(0.08))
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Calls", point.calls)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle())
                    .symbolSize(50)
                    .interpolationMethod(.linear)
                }
            }
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: callYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: 86400)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartYAxis {
                AxisMarks(values: callTicks.map { Double($0) }) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartLegend(.hidden)
            .chartPlotStyle { $0.background(.clear) }
            .allowsHitTesting(false)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ForEach(callTicks, id: \.self) { tick in
                        if let pos = proxy.position(
                            for: (x: chartDomain.lowerBound, y: Double(tick))
                        ) {
                            Text(compactCount(tick))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.blue)
                                .position(x: 4, y: pos.y)
                        }
                    }
                }
            }
        }
    }

    private var hourlyChartStack: some View {
        ZStack {
            // Bottom layer: Tokens chart (green)
            Chart(hourlyPoints) { point in
                if showTokens {
                    AreaMark(
                        x: .value("Hour", point.date),
                        y: .value("Tokens", point.tokens)
                    )
                    .foregroundStyle(.green.opacity(0.08))
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Hour", point.date),
                        y: .value("Tokens", point.tokens)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle())
                    .symbolSize(50)
                    .interpolationMethod(.linear)
                }
            }
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: tokenYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3600)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartYAxis {
                AxisMarks(values: tokenTicks.map { Double($0) }) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.15, dash: [2, 2]))
                }
            }
            .chartLegend(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ZStack(alignment: .topLeading) {
                        ForEach(tokenTicks, id: \.self) { tick in
                            if let pos = proxy.position(
                                for: (x: chartDomain.upperBound, y: Double(tick))
                            ) {
                                Text(QuotaFormatter.tokenCount(tick))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.green)
                                    .position(x: geometry.size.width - 4, y: pos.y)
                            }
                        }
                        // X-axis hour labels — skip some for 1d (24 points) to avoid overlap
                        ForEach(Array(hourlyPoints.enumerated()), id: \.element.id) { index, point in
                            let shouldShow = timeWindow == .fiveHour || index % 3 == 0
                            if shouldShow, let pos = proxy.position(
                                for: (x: point.date, y: tokenYDomain.lowerBound)
                            ) {
                                Text(point.hourLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .position(x: pos.x, y: geometry.size.height - 6)
                            }
                        }
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    guard let date: Date = proxy.value(atX: location.x) else { return }
                                    selectedHourlyPoint = hourlyPoints.min(by: {
                                        abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                    })
                                case .ended:
                                    selectedHourlyPoint = nil
                                }
                            }
                            .overlay(hourlyTooltipOverlay(proxy: proxy, geometry: geometry))
                    }
                }
            }

            // Top layer: Calls chart (blue)
            Chart(hourlyPoints) { point in
                if showCalls {
                    AreaMark(
                        x: .value("Hour", point.date),
                        y: .value("Calls", point.calls)
                    )
                    .foregroundStyle(.blue.opacity(0.08))
                    .interpolationMethod(.linear)

                    LineMark(
                        x: .value("Hour", point.date),
                        y: .value("Calls", point.calls)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle())
                    .symbolSize(50)
                    .interpolationMethod(.linear)
                }
            }
            .chartXScale(domain: chartDomain)
            .chartYScale(domain: callYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3600)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartYAxis {
                AxisMarks(values: callTicks.map { Double($0) }) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                }
            }
            .chartLegend(.hidden)
            .chartPlotStyle { $0.background(.clear) }
            .allowsHitTesting(false)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    ForEach(callTicks, id: \.self) { tick in
                        if let pos = proxy.position(
                            for: (x: chartDomain.lowerBound, y: Double(tick))
                        ) {
                            Text(compactCount(tick))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.blue)
                                .position(x: 4, y: pos.y)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section 3: Product Breakdown

    private var productBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppStrings.productUsage(language: language))
                .font(.headline.weight(.semibold))

            if snapshot.productBreakdown.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                HStack(alignment: .center, spacing: 24) {
                    donutChart
                    barChart
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    private var donutChart: some View {
        let top = Array(snapshot.productBreakdown.prefix(6))
        let otherTokens = snapshot.productBreakdown.dropFirst(6).reduce(0) { $0 + $1.tokens }
        let totalTokens = snapshot.productBreakdown.reduce(0) { $0 + $1.tokens }
        let totalCalls = snapshot.productBreakdown.reduce(0) { $0 + $1.calls }
        let allRecords: [(product: String, tokens: Int, color: Color)] = {
            var records: [(product: String, tokens: Int, color: Color)] = []
            for (i, r) in top.enumerated() {
                records.append((r.product, r.tokens, chartColors[i]))
            }
            if otherTokens > 0 {
                records.append(("Other", otherTokens, Color.gray))
            }
            return records
        }()

        return VStack(spacing: 8) {
            Chart(allRecords, id: \.product) { item in
                SectorMark(
                    angle: .value("Tokens", item.tokens),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    if totalTokens > 0 {
                        let pct = Double(item.tokens) / Double(totalTokens) * 100
                        if pct > 8 {
                            Text("\(Int(pct))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(width: 180, height: 180)

            if totalTokens > 0 {
                VStack(spacing: 2) {
                    Text("\(QuotaFormatter.tokenCount(totalTokens)) tokens")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text("\(QuotaFormatter.callCount(totalCalls)) calls")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(width: 180)
            }
        }
        .frame(width: 200)
    }

    private var barChart: some View {
        let displayData = Array(snapshot.productBreakdown.prefix(8))
        let maxTokens = displayData.map(\.tokens).max() ?? 1
        let totalTokens = displayData.reduce(0) { $0 + $1.tokens }

        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(displayData.enumerated()), id: \.element.product) { index, record in
                let colorIndex = originalIndex(for: record.product)
                let pct = totalTokens > 0 ? Double(record.tokens) / Double(totalTokens) * 100 : 0
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(chartColors[colorIndex % chartColors.count])
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(record.product)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            Text(String(format: "%.2f%%", pct))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(chartColors[colorIndex % chartColors.count].opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(record.tokens) / CGFloat(maxTokens), height: 10)
                        }
                        .frame(height: 10)

                        HStack(spacing: 10) {
                            Text("\(QuotaFormatter.callCount(record.calls)) calls")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text("\(QuotaFormatter.tokenCount(record.tokens)) tokens")
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func originalIndex(for product: String) -> Int {
        guard let idx = snapshot.productBreakdown.firstIndex(where: { $0.product == product }) else {
            return 0
        }
        return idx
    }


    // MARK: - Axis Utilities

    /// Format compact count: 1200 → "1.2K", 1500000 → "1.5M"
    private func compactCount(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000.0)
        }
        return "\(value)"
    }

    /// Compute nice round tick values for an axis.
    /// Returns values like [0, 200, 400, 600, 800] for a range of 0-750.
    private static func niceTicks(for values: [Int], desiredCount: Int) -> [Int] {
        guard let minVal = values.min(), let maxVal = values.max(), minVal < maxVal else {
            return [0, max(1, values.first ?? 0)]
        }

        let range = Double(maxVal - minVal)
        let rawStep = range / Double(max(desiredCount - 1, 1))
        let magnitude = pow(10, floor(log10(max(rawStep, 1))))
        let normalized = rawStep / magnitude

        let niceStep: Double
        if normalized <= 1.0 { niceStep = 1 * magnitude }
        else if normalized <= 2.0 { niceStep = 2 * magnitude }
        else if normalized <= 5.0 { niceStep = 5 * magnitude }
        else { niceStep = 10 * magnitude }

        // Extend range to nice round boundaries
        let start = floor(Double(minVal) / niceStep) * niceStep
        let end = ceil(Double(maxVal) / niceStep) * niceStep

        var ticks: [Int] = []
        var tick = start
        while tick <= end + niceStep * 0.001 {
            ticks.append(Int(tick))
            tick += niceStep
        }
        return ticks
    }
}

// MARK: - Preference Key

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
