//
//  AppleHealthSettingsView.swift
//  logcal
//
//  Created by Antriksh Johri on 20/08/26.
//

import SwiftUI
import SwiftData
import HealthKit

struct AppleHealthSettingsView: View {
    @ObservedObject private var healthKit = HealthKitService.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @Query(filter: #Predicate<MealEntry> { !$0.deleted })
    private var activeMeals: [MealEntry]
    
    @AppStorage("lastHealthKitSyncTimestamp") private var lastSyncTimestamp: Double = 0
    @State private var showSyncConfirmation = false
    @State private var syncSuccessMessage: String?
    
    private var formattedLastSync: String? {
        guard lastSyncTimestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: lastSyncTimestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Header & Status Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                    
                    Text("Apple Health")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Text("Sync your meals and macronutrients with Apple Health, and import active calories burned from your Apple Watch.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // 2. Connection Status Card
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: healthKit.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(healthKit.isAuthorized ? Theme.primaryGreen : Theme.warningAmber)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(healthKit.isAuthorized ? "Apple Health Connected" : "Connection Required")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text(healthKit.isAuthorized ? "Permissions granted for nutrition and activity" : "Grant permissions to sync meals & active burn")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        Task {
                            let _ = await healthKit.requestAuthorization()
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                await UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(healthKit.isAuthorized ? "Manage Permissions in Settings" : "Connect Apple Health")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(healthKit.isAuthorized ? Theme.primaryText(colorScheme: colorScheme) : .white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(healthKit.isAuthorized ? Theme.insetBackground(colorScheme: colorScheme) : Theme.primaryGreen)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                
                // 3. Synchronization Toggles (Only when available)
                if healthKit.isAvailable {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sync Preferences")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // Toggle 1: Write meals
                            Toggle(isOn: $healthKit.isHealthKitSyncEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Write Meals to Apple Health")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    Text("Sync calories, protein, carbs, fat, and fiber automatically")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                }
                            }
                            .tint(Theme.primaryGreen)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            // Toggle 2: Read active burn
                            Toggle(isOn: $healthKit.isHealthKitActiveBurnEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Import Active Calories Burned")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    Text("Read workout and movement calories from Apple Watch")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                }
                            }
                            .tint(Theme.primaryGreen)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .onChange(of: healthKit.isHealthKitActiveBurnEnabled) { oldValue, newValue in
                                if newValue {
                                    Task {
                                        await healthKit.refreshTodayActivity()
                                        healthKit.startObservingHealthChanges()
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            // Toggle 3: Net Calories / Adjust Goal
                            Toggle(isOn: $healthKit.adjustGoalWithActiveBurn) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Adjust Daily Goal with Burned Calories")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    Text("Remaining = Goal + Burned - Consumed")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                }
                            }
                            .tint(Theme.primaryGreen)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .disabled(!healthKit.isHealthKitActiveBurnEnabled)
                            .opacity(healthKit.isHealthKitActiveBurnEnabled ? 1.0 : 0.5)
                        }
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                    }
                }
                
                // 4. Historical Sync Section
                if healthKit.isHealthKitSyncEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Historical Data")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.horizontal, 4)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Backfill your existing LogCal meal history into Apple Health.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            
                            if let lastSync = formattedLastSync {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.primaryGreen)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("All \(activeMeals.count) meals synced")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.primaryGreen)
                                        Text("Last synced: \(lastSync)")
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Button {
                                Task {
                                    await healthKit.syncHistoricalMeals(activeMeals)
                                    lastSyncTimestamp = Date().timeIntervalSince1970
                                    syncSuccessMessage = "Successfully synced \(activeMeals.count) meals to Apple Health!"
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    if healthKit.isSyncing {
                                        ProgressView()
                                            .tint(Theme.primaryGreen)
                                            .padding(.trailing, 4)
                                        Text("Syncing \(activeMeals.count) meals...")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.primaryGreen)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 14, weight: .bold))
                                        Text(lastSyncTimestamp > 0 ? "Re-sync All \(activeMeals.count) Past Meals" : "Sync \(activeMeals.count) Past Meals to Health")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                .foregroundColor(Theme.primaryGreen)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(healthKit.isSyncing || activeMeals.isEmpty)
                        }
                        .padding(16)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                    }
                }
                
                // 5. Privacy Notice Footer
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    Text("Your health data remains secure and stored on your device.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(Theme.backgroundColor(colorScheme: colorScheme).ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthKit.checkAuthorizationStatus()
            Task {
                _ = await healthKit.requestAuthorization()
                if healthKit.isHealthKitActiveBurnEnabled {
                    await healthKit.refreshTodayActivity()
                }
            }
        }
    }
}
