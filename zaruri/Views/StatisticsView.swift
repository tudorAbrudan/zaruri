//
//  StatisticsView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import Combine

/// Statistics view showing dice roll statistics
struct StatisticsView: View {
    @ObservedObject var viewModel: DiceViewModel
    @ObservedObject private var statisticsViewModel: StatisticsViewModel
    
    init(viewModel: DiceViewModel) {
        self.viewModel = viewModel
        let svm = StatisticsViewModel()
        self._statisticsViewModel = ObservedObject(wrappedValue: svm)
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: isIPad ? 30 : 20) {
                // Overall statistics
                overallStatsCard
                
                // Value distribution
                if !statisticsViewModel.valueDistribution.isEmpty {
                    distributionCard
                }
            }
            .padding(isIPad ? 30 : 16)
            .frame(maxWidth: isIPad ? 800 : .infinity)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitle("Statistici", displayMode: .inline)
        .navigationBarItems(trailing:
            Button("Resetează") {
                statisticsViewModel.resetStatistics()
            }
        )
        .onAppear {
            statisticsViewModel.loadStatisticsFromHistory(viewModel.history)
        }
        .onReceive(viewModel.$history.dropFirst()) { _ in
            statisticsViewModel.loadStatisticsFromHistory(viewModel.history)
        }
    }
    
    // MARK: - Overall Stats Card
    
    private var overallStatsCard: some View {
        VStack(alignment: .leading, spacing: isIPad ? 24 : 16) {
            Text("Statistici generale")
                .font(.system(size: isIPad ? 22 : 17, weight: .bold))
            
            // iOS 13 compatible grid using VStack and HStack
            VStack(spacing: isIPad ? 20 : 16) {
                HStack(spacing: isIPad ? 24 : 16) {
                    StatisticItem(
                        title: "Total aruncări",
                        value: "\(statisticsViewModel.totalRolls)",
                        isIPad: isIPad
                    )
                    StatisticItem(
                        title: "Medie",
                        value: statisticsViewModel.formattedAverage,
                        isIPad: isIPad
                    )
                }
                HStack(spacing: isIPad ? 24 : 16) {
                    StatisticItem(
                        title: "Minim",
                        value: "\(statisticsViewModel.minRoll)",
                        isIPad: isIPad
                    )
                    StatisticItem(
                        title: "Maxim",
                        value: "\(statisticsViewModel.maxRoll)",
                        isIPad: isIPad
                    )
                }
            }
        }
        .padding(isIPad ? 24 : 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(isIPad ? 16 : 12)
    }
    
    // MARK: - Distribution Card
    
    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            Text("Distribuție valori")
                .font(.system(size: isIPad ? 22 : 17, weight: .bold))
            
            ForEach(statisticsViewModel.valueDistribution, id: \.value) { item in
                DistributionRow(
                    value: item.value,
                    count: item.count,
                    percentage: item.percentage,
                    isIPad: isIPad
                )
            }
        }
        .padding(isIPad ? 24 : 16)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(isIPad ? 16 : 12)
    }
}

// MARK: - Statistic Item

struct StatisticItem: View {
    let title: String
    let value: String
    var isIPad: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(isIPad ? .subheadline : .caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: isIPad ? 32 : 22, weight: .bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isIPad ? 16 : 12)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(isIPad ? 12 : 8)
    }
}

// MARK: - Distribution Row

struct DistributionRow: View {
    let value: Int
    let count: Int
    let percentage: Double
    var isIPad: Bool = false
    
    var body: some View {
        HStack(spacing: isIPad ? 16 : 12) {
            Text("\(value)")
                .font(.system(size: isIPad ? 20 : 17, weight: .bold))
                .frame(width: isIPad ? 40 : 30)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: isIPad ? 28 : 20)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: isIPad ? 28 : 20)
                }
                .cornerRadius(isIPad ? 14 : 10)
            }
            .frame(height: isIPad ? 28 : 20)
            
            Text("\(Int(percentage))%")
                .font(isIPad ? .subheadline : .caption)
                .foregroundColor(.secondary)
                .frame(width: isIPad ? 60 : 50, alignment: .trailing)
        }
        .padding(.vertical, isIPad ? 4 : 2)
    }
}
