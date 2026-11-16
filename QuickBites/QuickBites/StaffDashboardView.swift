//

//  StaffDashboardView.swift

//  QuickBites

//

//  Created by Karakat Tursynbayeva on 11/5/26.

//



import SwiftUI


struct StaffDashboardView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var buffets: [Buffet] = []
    @State private var error: String?
    @State private var loading = false
    @State private var unreadNotifications = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {
                        Text("Staff Dashboard")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text(
                            "Manage your buffets, meals, pickup slots, and orders."
                        )
                        .foregroundStyle(.gray)

                        if loading {
                            ProgressView("Loading...")
                        }

                        if let error {
                            Text(error)
                                .foregroundStyle(.red)
                        }

                        ForEach(buffets) { buffet in
                            NavigationLink {
                                StaffBuffetView(buffet: buffet)
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    Text(buffet.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)

                                    Text(buffet.location)
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)

                                    Label(
                                        "Manage Buffet",
                                        systemImage: "arrow.right.circle"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(Color.accentCyan)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding(16)
                                .background(
                                    Color.darkCard,
                                    in: RoundedRectangle(
                                        cornerRadius: 16
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Button("Sign Out") {
                            session.signOut()
                        }
                        .foregroundStyle(Color.accentCyan)
                    }
                    .padding(20)
                }
                .refreshable {
                    await load()
                    await refreshUnreadCount()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StaffNotificationsView()
                    } label: {
                        HStack(spacing: 5) {
                            Image(
                                systemName: unreadNotifications > 0
                                    ? "bell.badge.fill"
                                    : "bell"
                            )

                            if unreadNotifications > 0 {
                                Text(
                                    unreadNotifications > 99
                                        ? "99+"
                                        : String(unreadNotifications)
                                )
                                .font(.caption.bold())
                            }
                        }
                        .foregroundStyle(Color.accentCyan)
                        .accessibilityLabel(
                            "Notifications, \(unreadNotifications) unread"
                        )
                    }
                }
            }
            .task {
                await load()
                await refreshUnreadCount()

                while !Task.isCancelled {
                    do {
                        try await Task.sleep(
                            for: .seconds(15)
                        )
                    } catch {
                        break
                    }

                    if scenePhase == .active {
                        await refreshUnreadCount()
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await refreshUnreadCount()
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        loading = true

        defer {
            loading = false
        }

        do {
            buffets = try await APIService.shared.getMyBuffets()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    private func refreshUnreadCount() async {
        do {
            let items = try await APIService.shared.notifications()

            unreadNotifications = items.filter {
                !$0.read
            }.count
        } catch {
            
        }
    }
}



struct StaffBuffetView: View {

    let buffet: Buffet



    var body: some View {

        List {

            Section("Analytics") {
                NavigationLink {
                    StaffAnalyticsView(buffet: buffet)
                } label: {
                    Label("Sales Analytics", systemImage: "chart.bar.xaxis")
                }
            }

            Section("Orders") {

                NavigationLink {

                    StaffOrdersView(buffet: buffet)

                } label: {

                    Label("Incoming Orders", systemImage: "receipt")

                }

            }



            Section("Menu Management") {

                NavigationLink {

                    StaffMealsView(buffet: buffet)

                } label: {

                    Label("Manage Meals", systemImage: "fork.knife")

                }



                NavigationLink {

                    BuffetMenuSeederView(buffet: buffet)

                } label: {

                    Label(

                        "Import Tole Bi Menu",

                        systemImage: "square.and.arrow.down"

                    )

                }

            }



            Section("Operations") {

                NavigationLink {

                    StaffSlotsView(buffet: buffet)

                } label: {

                    Label("Pickup Slots", systemImage: "clock")

                }



                NavigationLink {

                    StaffFeedbackView(buffet: buffet)

                } label: {

                    Label("Customer Feedback", systemImage: "star.bubble")

                }

            }

        }

        .navigationTitle(buffet.name)

    }

}



struct StaffOrdersView: View {

    let buffet: Buffet



    @State private var orders: [QuickOrder] = []

    @State private var page = 0

    @State private var totalPages = 0

    @State private var error: String?

    @State private var filter = "ALL"

    @State private var processing: UUID?

    @State private var loading = false



    private let statuses = [

        "ALL",

        "PENDING",

        "CONFIRMED",

        "PREPARING",

        "READY",

        "COMPLETED",

        "CANCELLED"

    ]



    var body: some View {

        ZStack {

            Color.darkBackground.ignoresSafeArea()



            ScrollView {

                VStack(spacing: 14) {

                    statusPicker



                    if loading {

                        ProgressView("Loading orders...")

                    }



                    if let error {

                        Text(error)

                            .foregroundStyle(.red)



                        Button("Retry") {

                            Task { await load() }

                        }

                    }



                    if !loading && error == nil && orders.isEmpty {

                        EmptyStateView(

                            message: "No orders for this filter",

                            symbol: "receipt"

                        )

                    }



                    LazyVStack(spacing: 14) {

                        ForEach(orders) { order in

                            orderCard(order)

                        }

                    }



                    paginationControls

                }

                .padding(20)

            }

            .refreshable { await load() }

        }

        .navigationTitle("Incoming Orders")

        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    Task { await load() }

                } label: {

                    Image(systemName: "arrow.clockwise")

                }

            }

        }

        .onChange(of: filter) { _ in

            page = 0

            Task { await load() }

        }

        .task { await load() }

    }



    private var statusPicker: some View {

        Picker("Status", selection: $filter) {

            ForEach(statuses, id: \.self) { status in

                Text(status.capitalized)

                    .tag(status)

            }

        }

        .pickerStyle(.menu)

        .tint(Color.accentCyan)

    }



    private func orderCard(_ order: QuickOrder) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            orderHeader(order)



            Divider()



            customerDetails(order)



            orderDates(order)



            Divider()



            orderItems(order)



            Divider()



            orderTotal(order)



            orderActions(order)

        }

        .foregroundStyle(.white)

        .padding(16)

        .background(

            Color.darkCard,

            in: RoundedRectangle(cornerRadius: 16)

        )

    }



    private func orderHeader(_ order: QuickOrder) -> some View {

        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 5) {

                Text("PICKUP CODE")

                    .font(.caption)

                    .foregroundStyle(.gray)



                Text(order.pickupCode ?? "Unavailable")

                    .font(

                        .system(

                            size: 32,

                            weight: .bold,

                            design: .monospaced

                        )

                    )

                    .foregroundStyle(Color.accentCyan)



                Text("Order #\(String(format: "%03d", order.queueNumber))")

                    .font(.caption)

                    .foregroundStyle(.gray)

            }



            Spacer()



            Text(

                order.status.replacingOccurrences(

                    of: "_",

                    with: " "

                )

            )

            .font(.caption.bold())

            .foregroundStyle(Color.accentCyan)

        }

    }



    private func customerDetails(_ order: QuickOrder) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Label(

                order.customerName ?? "Student",

                systemImage: "person.fill"

            )

            .font(.headline)



            if let email = order.customerEmail {

                Text(email)

                    .font(.caption)

                    .foregroundStyle(.gray)

            }

        }

    }



    private func orderDates(_ order: QuickOrder) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            if let orderedAt = order.orderedAt {

                Label(

                    "Ordered: \(formattedDate(orderedAt))",

                    systemImage: "calendar"

                )

                .font(.subheadline)

            } else {

                Label(

                    "Ordered: Not available",

                    systemImage: "calendar"

                )

                .font(.subheadline)

            }



            Label(

                "Pickup: \(formattedDate(order.pickupTime))",

                systemImage: "clock"

            )

            .font(.subheadline)

        }

    }



    private func formattedDate(_ date: Date) -> String {

        date.formatted(

            date: .abbreviated,

            time: .shortened

        )

    }



    private func orderItems(_ order: QuickOrder) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Order Items")

                .font(.headline)



            ForEach(order.items, id: \.mealId) { item in

                HStack {

                    Text("\(item.quantity) × \(item.mealName)")



                    Spacer()



                    Text(PriceFormat.tenge(item.lineTotal))

                }

                .font(.subheadline)

            }

        }

    }



    private func orderTotal(_ order: QuickOrder) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack {

                Text("Total")

                    .fontWeight(.bold)



                Spacer()



                Text(PriceFormat.tenge(order.total))

                    .fontWeight(.bold)

                    .foregroundStyle(Color.accentCyan)

            }



            Text(

                "Payment: \(order.paymentStatus.replacingOccurrences(of: "_", with: " "))"

            )

            .font(.caption)

            .foregroundStyle(.gray)

        }

    }



    @ViewBuilder

    private func orderActions(_ order: QuickOrder) -> some View {

        if let next = nextStatus(order.status) {

            Button {

                Task {

                    await advance(order.id, next: next)

                }

            } label: {

                Text(

                    next == "CONFIRMED"

                        ? "Accept Order"

                        : "Mark as \(next.capitalized)"

                )

                .frame(maxWidth: .infinity)

            }

            .buttonStyle(.borderedProminent)

            .tint(Color.accentCyan)

            .disabled(processing != nil)

        }



        if order.status != "COMPLETED" &&

            order.status != "CANCELLED" {

            Button("Cancel Order", role: .destructive) {

                Task {

                    await cancel(order.id)

                }

            }

            .disabled(processing != nil)

        }

    }



    private var paginationControls: some View {

        HStack {

            Button("Previous") {

                page -= 1

                Task { await load() }

            }

            .disabled(page == 0)



            Spacer()



            Text("Page \(page + 1) of \(max(totalPages, 1))")

                .foregroundStyle(.gray)



            Spacer()



            Button("Next") {

                page += 1

                Task { await load() }

            }

            .disabled(page + 1 >= totalPages)

        }

    }



    private func nextStatus(_ current: String) -> String? {

        switch current {

        case "PENDING":

            return "CONFIRMED"

        case "CONFIRMED":

            return "PREPARING"

        case "PREPARING":

            return "READY"

        case "READY":

            return "COMPLETED"

        default:

            return nil

        }

    }



    @MainActor

    private func load() async {

        loading = true

        defer { loading = false }



        do {

            let result = try await APIService.shared.buffetOrders(

                buffet.id,

                status: filter == "ALL" ? nil : filter,

                page: page

            )



            orders = result.content

            totalPages = result.totalPages

            error = nil

        } catch {

            self.error = error.localizedDescription

        }

    }



    @MainActor

    private func advance(_ id: UUID, next: String) async {

        processing = id

        defer { processing = nil }



        do {

            _ = try await APIService.shared.updateOrderStatus(

                id,

                status: next

            )



            await load()

        } catch {

            self.error = error.localizedDescription

        }

    }



    @MainActor

    private func cancel(_ id: UUID) async {

        processing = id

        defer { processing = nil }



        do {

            _ = try await APIService.shared.staffCancel(id)

            await load()

        } catch {

            self.error = error.localizedDescription

        }

    }

}



struct StaffMealsView: View {

    let buffet: Buffet



    @State private var meals: [Meal] = []

    @State private var error: String?

    @State private var showingAdd = false



    var body: some View {

        List {

            if let error {

                Text(error)

                    .foregroundStyle(.red)

            }



            ForEach(meals) { meal in

                NavigationLink {

                    EditMealView(

                        meal: meal,

                        onSaved: {

                            Task { await load() }

                        }

                    )

                } label: {

                    VStack(alignment: .leading, spacing: 5) {

                        Text(meal.name)



                        Text(PriceFormat.tenge(meal.price))

                            .foregroundStyle(Color.accentCyan)



                        Text(

                            meal.available

                                ? "Available"

                                : "Unavailable"

                        )

                        .font(.caption)

                    }

                }

            }

        }

        .navigationTitle("Manage Meals")

        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showingAdd = true

                } label: {

                    Image(systemName: "plus")

                }

            }

        }

        .sheet(

            isPresented: $showingAdd,

            onDismiss: {

                Task { await load() }

            }

        ) {

            AddMealView(buffet: buffet)

        }

        .refreshable { await load() }

        .task { await load() }

    }



    @MainActor

    private func load() async {

        do {

            meals = try await APIService.shared.getMenu(

                buffetId: buffet.id

            ).meals



            error = nil

        } catch {

            self.error = error.localizedDescription

        }

    }

}



struct AddMealView: View {

    let buffet: Buffet



    @Environment(\.dismiss) private var dismiss



    @State private var name = ""

    @State private var description = ""

    @State private var price = ""

    @State private var capacity = ""

    @State private var error: String?



    var body: some View {

        NavigationStack {

            Form {

                TextField("Meal name", text: $name)

                TextField("Description", text: $description)



                TextField("Price in KZT", text: $price)

                    .keyboardType(.decimalPad)



                TextField("Capacity (optional)", text: $capacity)

                    .keyboardType(.numberPad)



                if let error {

                    Text(error)

                        .foregroundStyle(.red)

                }



                Button("Create Meal") {

                    Task { await save() }

                }

            }

            .navigationTitle("Add Meal")

            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {

                    Button("Close") {

                        dismiss()

                    }

                }

            }

        }

    }



    @MainActor

    private func save() async {

        guard

            !name.trimmingCharacters(in: .whitespaces).isEmpty,

            let amount = Decimal(

                string: price.replacingOccurrences(

                    of: ",",

                    with: "."

                )

            ),

            amount >= 0

        else {

            error = "Enter a valid name and price."

            return

        }



        if !capacity.isEmpty &&

            (Int(capacity) == nil || Int(capacity)! < 0) {

            error = "Enter a valid capacity."

            return

        }



        do {

            _ = try await APIService.shared.createMeal(

                buffetId: buffet.id,

                name: name,

                description: description,

                price: amount,

                capacity: Int(capacity)

            )



            dismiss()

        } catch {

            self.error = error.localizedDescription

        }

    }

}



struct EditMealView: View {

    let meal: Meal

    let onSaved: () -> Void



    @Environment(\.dismiss) private var dismiss



    @State private var name: String

    @State private var description: String

    @State private var price: String

    @State private var capacity: String

    @State private var available: Bool

    @State private var error: String?



    init(meal: Meal, onSaved: @escaping () -> Void) {

        self.meal = meal

        self.onSaved = onSaved



        _name = State(initialValue: meal.name)

        _description = State(

            initialValue: meal.description ?? ""

        )

        _price = State(

            initialValue: NSDecimalNumber(

                decimal: meal.price

            ).stringValue

        )

        _capacity = State(

            initialValue: meal.capacity.map(String.init) ?? ""

        )

        _available = State(initialValue: meal.available)

    }



    var body: some View {

        Form {

            TextField("Name", text: $name)

            TextField("Description", text: $description)



            TextField("Price", text: $price)

                .keyboardType(.decimalPad)



            TextField("Capacity", text: $capacity)

                .keyboardType(.numberPad)



            Toggle("Available", isOn: $available)



            if let error {

                Text(error)

                    .foregroundStyle(.red)

            }



            Button("Save Changes") {

                Task { await save() }

            }



            Button("Delete Meal", role: .destructive) {

                Task { await delete() }

            }

        }

        .navigationTitle("Edit Meal")

    }



    @MainActor

    private func save() async {

        guard

            let amount = Decimal(

                string: price.replacingOccurrences(

                    of: ",",

                    with: "."

                )

            ),

            amount >= 0,

            !name.trimmingCharacters(in: .whitespaces).isEmpty

        else {

            error = "Enter a valid name and price."

            return

        }



        do {

            _ = try await APIService.shared.updateMeal(

                meal.id,

                name: name,

                description: description,

                price: amount,

                capacity: Int(capacity)

            )



            _ = try await APIService.shared.setMealAvailability(

                meal.id,

                available: available

            )



            onSaved()

            dismiss()

        } catch {

            self.error = error.localizedDescription

        }

    }



    @MainActor

    private func delete() async {

        do {

            try await APIService.shared.deleteMeal(meal.id)



            onSaved()

            dismiss()

        } catch {

            self.error = error.localizedDescription

        }

    }

}



struct StaffSlotsView: View {

    let buffet: Buffet



    @State private var slots: [PickupSlot] = []

    @State private var date = Date().addingTimeInterval(3600)

    @State private var capacity = "20"

    @State private var error: String?



    var body: some View {

        Form {

            Section("Create Pickup Slot") {

                DatePicker(

                    "Pickup time",

                    selection: $date,

                    in: Date()...,

                    displayedComponents: [.date, .hourAndMinute]

                )



                TextField("Capacity", text: $capacity)

                    .keyboardType(.numberPad)



                Button("Create Slot") {

                    Task { await create() }

                }

            }



            Section("Upcoming Slots") {

                ForEach(slots) { slot in

                    VStack(alignment: .leading) {

                        Text(

                            slot.slotTime.formatted(

                                date: .abbreviated,

                                time: .shortened

                            )

                        )



                        Text(

                            "\(slot.remaining) / \(slot.capacity) remaining"

                        )

                        .font(.caption)

                    }

                }

            }



            if let error {

                Text(error)

                    .foregroundStyle(.red)

            }

        }

        .navigationTitle("Pickup Slots")

        .refreshable { await load() }

        .task { await load() }

    }



    @MainActor

    private func load() async {

        do {

            slots = try await APIService.shared.getSlots(

                buffetId: buffet.id

            )



            error = nil

        } catch {

            self.error = error.localizedDescription

        }

    }



    @MainActor

    private func create() async {

        guard

            let count = Int(capacity),

            (1...500).contains(count)

        else {

            error = "Capacity must be between 1 and 500."

            return

        }



        do {

            _ = try await APIService.shared.createSlot(

                buffetId: buffet.id,

                time: date,

                capacity: count

            )



            await load()

        } catch {

            self.error = error.localizedDescription

        }

    }

}



struct StaffFeedbackView: View {

    let buffet: Buffet



    @State private var feedback: [FeedbackItem] = []

    @State private var error: String?



    var body: some View {

        List {

            if let error {

                Text(error)

                    .foregroundStyle(.red)

            }



            ForEach(feedback) { item in

                VStack(alignment: .leading, spacing: 8) {

                    Text(item.emojiRating.capitalized)

                        .font(.headline)



                    Text(item.comment ?? "No comment")



                    Text(item.createdAt?.formatted() ?? "Date unavailable")

                        .font(.caption)

                        .foregroundStyle(.gray)



                    Button(

                        item.flagged

                            ? "Remove Flag"

                            : "Flag Feedback"

                    ) {

                        Task { await flag(item) }

                    }

                }

            }

        }

        .navigationTitle("Customer Feedback")

        .refreshable { await load() }

        .task { await load() }

    }



    @MainActor

    private func load() async {

        do {

            feedback = try await APIService.shared.buffetFeedback(

                buffet.id

            )



            error = nil

        } catch {

            self.error = error.localizedDescription

        }

    }



    @MainActor

    private func flag(_ item: FeedbackItem) async {

        do {

            _ = try await APIService.shared.flagFeedback(

                item.id,

                flagged: !item.flagged

            )



            await load()

        } catch {

            self.error = error.localizedDescription

        }

    }

}
