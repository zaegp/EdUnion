//
//  ProgressBarView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/18.
//

import SwiftUI

struct ProgressBarView: View {
    var value: Double
    var range: ClosedRange<Double> = 0...1
    var lineWidth: CGFloat = 20
    var separatorWidth: CGFloat = 2
    var separatorColor: Color = .white
    var segments: Int = 100

    private var progressPercentage: String {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound) * 100
        return String(format: "%.0f%%", percentage)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .orange
                        ]),
                        center: .top
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: value)

            ForEach(0..<segments) { i in
                let angle = Angle(degrees: (360.0 / Double(segments)) * Double(i))
                Rectangle()
                    .fill(separatorColor)
                    .frame(width: separatorWidth, height: lineWidth)
                    .offset(y: -lineWidth / 2)
                    .rotationEffect(angle)
            }

            Text(progressPercentage)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.8), value: value)
        }
        .frame(width: 200, height: 200)
    }
}

struct ProgressContentView: View {
    @State private var progressValue = 0.5

    var body: some View {
        HStack {
            // 進度條
            ProgressBarView(value: progressValue)
                .padding()

            // 統計資訊
            VStack(alignment: .leading, spacing: 40) {
                StatisticView(iconName: "pencil", title: "基本目標", value: "1,301")
                StatisticView(iconName: "fork.knife", title: "食物", value: "0")
                StatisticView(iconName: "flame", title: "運動", value: "0")
            }
            .padding()
        }
        .padding()
    }
}

// 統計資訊的自定義視圖
struct StatisticView: View {
    var iconName: String
    var title: String
    var value: String

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressContentView()
    }
}

