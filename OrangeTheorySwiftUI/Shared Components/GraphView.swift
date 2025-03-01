//
//  GraphView.swift
//  OrangeTheorySwiftUI
//
//  Created by Nathan Molby on 2/11/25.
//

import SwiftUI
import Charts

struct GraphConfiguration {
    let scale: ClosedRange<Int>
    
    let yMarkers: [Int]
    
    // Making the format generic would add a lot of complexity
    // Since this graph doesn't need to support other formats,
    // We'll just use this boolean to reduce scope
    let formatAsPercentage: Bool
}

struct GraphView<M: Dimension>: View {
    let metricBySecond: [(Int, Double)]
    let averageBySecond: [(Int, Double)]
    let configuration: GraphConfiguration
    
    @Environment(\.configuration.chartWidth) var chartWidth
    
    func averageAt(_ second: Int) -> Double? {
        return averageBySecond.first(where: { $0.0 == second })?.1
    }
    
    var chartXScale: ClosedRange<Int> {
        let chartMax = averageBySecond.map(\.0).max() ?? 0
        let chartMin = max(0, chartMax - Int(chartWidth.converted(to: .seconds).value))
        
        return chartMin...chartMax
    }

    var body: some View {
        Chart {
            ForEach(averageBySecond.map(\.0), id: \.self) { secondOnChart in
                if let averageAtSecond = averageAt(secondOnChart), chartXScale.contains(secondOnChart) {
                    AreaMark(x: .value("Second", secondOnChart), y: .value("Average", averageAtSecond))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .chartForeground,
                                    .chartSecondary
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    LineMark(x: .value("Second", secondOnChart), y: .value("Average", averageAtSecond), series: .value("Average", "A"))
                        .foregroundStyle(.accent)
                        .lineStyle(.init(lineWidth: 10))
                }
            }
            
            //TODO: ensure metrics prior to start of scale don't display
            ForEach(metricBySecond, id: \.0) { second, metric in
                LineMark(x: .value("Second", second), y: .value("Metric", metric))
                    .foregroundStyle(.white)
                    .lineStyle(.init(lineWidth: 7))
            }
            

        }
        .chartXAxis(.hidden)
        .chartYScale(domain: configuration.scale)
        .chartXScale(domain: chartXScale)
        .chartYAxis {
            AxisMarks(position: .trailing, values: configuration.yMarkers) {
                if configuration.formatAsPercentage {
                    AxisValueLabel(format: Decimal.FormatStyle.Percent.percent.scale(1))
                        .font(.medium.bold())
                        .foregroundStyle(.white)
                } else {
                    AxisValueLabel()
                        .font(.medium.bold())
                        .foregroundStyle(.white)
                }
                
                AxisGridLine()
                    .foregroundStyle(.white)
            }
        }
        .clipped()

    }
}

#Preview("Speed") {
    let speedHistory = PreviewTreadmillDataProvider().speedHistory
    let formattedSpeedHistory = Configuration().formatSpeedForGraph(speedHistory)
    let averageSpeedHistory = Configuration().calculateSpeedAverageForGraph(speedHistory)
    
    GraphView(metricBySecond: formattedSpeedHistory, averageBySecond: averageSpeedHistory, configuration: GraphConfiguration(scale: 0...15, yMarkers: [3, 6, 9, 12], formatAsPercentage: false))
        .environment(\.configuration.chartWidth, .init(value: 10, unit: .minutes))
        .frame(height: 400)
}
