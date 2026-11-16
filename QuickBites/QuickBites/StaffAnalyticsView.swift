import SwiftUI
import Charts

struct StaffAnalyticsResponse: Decodable {
    let buffetId: UUID
    let buffetName: String
    let startDate: String
    let endDate: String
    let totalOrders: Int
    let pendingOrders: Int
    let confirmedOrders: Int
    let preparingOrders: Int
    let readyOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let paidOrders: Int
    let soldItems: Int
    let revenue: Decimal
    let averageOrderValue: Decimal
    let dailyStatistics: [StaffDailyStatistic]
}

struct StaffDailyStatistic: Decodable, Identifiable {
    let date: String
    let orders: Int
    let revenue: Decimal

    var id: String { date }

    var chartDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Almaty")
        return formatter.date(from: date)
    }
}

extension APIService {
    func staffAnalytics(buffetId: UUID, days: Int) async throws -> StaffAnalyticsResponse {
        guard let token = KeychainManager.readToken() else {
            throw APIError.serverError(401, "Please sign in again.")
        }

        let path = "http://localhost:8080/api/buffets/\(buffetId.uuidString)/analytics?days=\(days)"
        guard let url = URL(string: path) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Request failed."
            throw APIError.serverError(http.statusCode, message)
        }
        return try JSONDecoder().decode(StaffAnalyticsResponse.self, from: data)
    }
}

struct StaffAnalyticsView: View {
    let buffet: Buffet

    @State private var selectedDays = 7
    @State private var analytics: StaffAnalyticsResponse?
    @State private var loading = false
    @State private var errorMessage: String?

    private let periods = [1, 7, 30]

    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    periodPicker

                    if loading && analytics == nil {
                        ProgressView("Loading analytics...")
                            .tint(Color.accentCyan)
                    }

                    if let errorMessage {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                            Button("Retry") {
                                Task { await load() }
                            }
                        }
                    }

                    if let analytics {
                        overview(analytics)
                        ordersChart(analytics)
                        revenueChart(analytics)
                        orderStatusSection(analytics)
                    }
                }
                .padding(20)
            }
            .refreshable { await load() }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedDays) { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(buffet.name)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Sales and order performance")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedDays) {
            Text("Today").tag(1)
            Text("7 Days").tag(7)
            Text("30 Days").tag(30)
        }
        .pickerStyle(.segmented)
    }

    private func overview(_ data: StaffAnalyticsResponse) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard("Orders", value: "\(data.totalOrders)", symbol: "bag")
            metricCard("Revenue", value: PriceFormat.tenge(data.revenue), symbol: "banknote")
            metricCard("Completed", value: "\(data.completedOrders)", symbol: "checkmark.circle")
            metricCard("Average Paid Order", value: PriceFormat.tenge(data.averageOrderValue), symbol: "chart.line.uptrend.xyaxis")
            metricCard("Paid Orders", value: "\(data.paidOrders)", symbol: "creditcard")
            metricCard("Sold Items", value: "\(data.soldItems)", symbol: "fork.knife")
        }
    }

    private func metricCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Color.accentCyan)
            Text(value)
                .font(.title3.bold())
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func ordersChart(_ data: StaffAnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Orders by Day")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(data.dailyStatistics) { day in
                BarMark(
                    x: .value("Date", day.date),
                    y: .value("Orders", day.orders)
                )
                .foregroundStyle(Color.accentCyan)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func revenueChart(_ data: StaffAnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Revenue by Day")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(data.dailyStatistics) { day in
                LineMark(
                    x: .value("Date", day.date),
                    y: .value("Revenue", NSDecimalNumber(decimal: day.revenue).doubleValue)
                )
                .foregroundStyle(Color.accentCyan)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Date", day.date),
                    y: .value("Revenue", NSDecimalNumber(decimal: day.revenue).doubleValue)
                )
                .foregroundStyle(Color.accentCyan)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func orderStatusSection(_ data: StaffAnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Order Status Breakdown")
                .font(.headline)
                .foregroundStyle(.white)

            statusRow("Pending", count: data.pendingOrders)
            statusRow("Confirmed", count: data.confirmedOrders)
            statusRow("Preparing", count: data.preparingOrders)
            statusRow("Ready", count: data.readyOrders)
            statusRow("Completed", count: data.completedOrders)
            statusRow("Cancelled", count: data.cancelledOrders)
        }
        .padding(16)
        .background(Color.darkCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statusRow(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.gray)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    @MainActor
    private func load() async {
        loading = true
        errorMessage = nil
        defer { loading = false }

        do {
            analytics = try await APIService.shared.staffAnalytics(
                buffetId: buffet.id,
                days: selectedDays
            )
        } catch {
            analytics = nil
            errorMessage = error.localizedDescription
        }
    }
}
