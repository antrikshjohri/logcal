//
//  CustomizeDashboardSheet.swift
//  logcal
//
//  Created by Antriksh Johri on 20/08/26.
//

import SwiftUI

enum DashboardSectionType: String, CaseIterable, Codable, Identifiable {
    case calories = "calories"
    case macros = "macros"
    case weeklyTrend = "weeklyTrend"
    case goalStreak = "goalStreak"
    case activity = "activity"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .calories: return "Calorie Card"
        case .macros: return "Macros Split"
        case .weeklyTrend: return "Weekly Trend"
        case .goalStreak: return "Daily Goal & Streak"
        case .activity: return "Activity & Energy Balance"
        }
    }
    
    var subtitle: String {
        switch self {
        case .calories: return "Daily calorie ring, budget & remaining intake"
        case .macros: return "Protein, Carbs, Fats & Fiber breakdown"
        case .weeklyTrend: return "7-day nutrient bar charts and daily averages"
        case .goalStreak: return "Calorie target shortcut and logging streak"
        case .activity: return "Apple Health active burn, steps, workouts & TDEE"
        }
    }
    
    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .macros: return "chart.pie.fill"
        case .weeklyTrend: return "chart.bar.fill"
        case .goalStreak: return "bolt.fill"
        case .activity: return "figure.run"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .calories: return Theme.primaryGreen
        case .macros: return Color(red: 0.95, green: 0.38, blue: 0.38)
        case .weeklyTrend: return Color(red: 0.95, green: 0.70, blue: 0.25)
        case .goalStreak: return Theme.warningAmber
        case .activity: return Color(red: 0.30, green: 0.75, blue: 0.95)
        }
    }
}

struct CustomizeDashboardSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("dashboardSectionOrder") private var storedOrder: String = "calories,macros,weeklyTrend,goalStreak,activity"
    @AppStorage("showDashboardCalories") private var showCaloriesCard: Bool = true
    @AppStorage("showDashboardMacros") private var showMacrosCard: Bool = true
    @AppStorage("showDashboardWeeklyTrend") private var showWeeklyTrendCard: Bool = true
    @AppStorage("showDashboardGoalStreak") private var showGoalStreakCard: Bool = true
    @AppStorage("showDashboardActivity") private var showActivityCard: Bool = true
    
    @State private var sections: [DashboardSectionType] = []
    
    private func binding(for section: DashboardSectionType) -> Binding<Bool> {
        switch section {
        case .calories: return $showCaloriesCard
        case .macros: return $showMacrosCard
        case .weeklyTrend: return $showWeeklyTrendCard
        case .goalStreak: return $showGoalStreakCard
        case .activity: return $showActivityCard
        }
    }
    
    private var activeCount: Int {
        var count = 0
        if showCaloriesCard { count += 1 }
        if showMacrosCard { count += 1 }
        if showWeeklyTrendCard { count += 1 }
        if showGoalStreakCard { count += 1 }
        if showActivityCard { count += 1 }
        return count
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Drag rows to reorder. Toggle switches to hide or show sections on your dashboard.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                List {
                    ForEach(sections) { section in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(section.iconColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: section.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(section.iconColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(section.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                
                                Text(section.subtitle)
                                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: binding(for: section))
                                .labelsHidden()
                                .tint(Theme.primaryGreen)
                                .disabled(activeCount <= 1 && binding(for: section).wrappedValue)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Theme.cardBackground(colorScheme: colorScheme))
                    }
                    .onMove { fromOffsets, toOffset in
                        sections.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        saveOrder()
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
                
                // Footer: Reset to Default
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sections = DashboardSectionType.allCases
                        showCaloriesCard = true
                        showMacrosCard = true
                        showWeeklyTrendCard = true
                        showGoalStreakCard = true
                        showActivityCard = true
                        saveOrder()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Default Order & Visibility")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .background(Theme.backgroundColor(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Customize Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .onAppear {
                loadOrder()
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func loadOrder() {
        let keys = storedOrder.split(separator: ",").map { String($0) }
        var parsed: [DashboardSectionType] = []
        for key in keys {
            if let section = DashboardSectionType(rawValue: key), !parsed.contains(section) {
                parsed.append(section)
            }
        }
        for section in DashboardSectionType.allCases {
            if !parsed.contains(section) {
                parsed.append(section)
            }
        }
        sections = parsed
    }
    
    private func saveOrder() {
        storedOrder = sections.map { $0.rawValue }.joined(separator: ",")
    }
}
