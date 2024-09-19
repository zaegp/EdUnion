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
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            // 前景圆环（进度条）使用渐变色
            Circle()
                .trim(from: 0, to: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor(red: 0.92, green: 0.37, blue: 0.16, alpha: 1.00)),
                            .white
                        ]),
                        center: .top
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // 将进度条起点调整到顶部
            
            // 分隔线
            ForEach(0..<segments) { i in
                let angle = Angle(degrees: (360.0 / Double(segments)) * Double(i))
                Rectangle()
                    .fill(separatorColor)
                    .frame(width: separatorWidth, height: lineWidth)
                    .offset(y: -lineWidth / 2)
                    .rotationEffect(angle)
            }
            
            // 中间的进度百分比
            Text(progressPercentage)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 200, height: 200)
        }
        .frame(width: 200, height: 200) // 设定圆形进度条的尺寸
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            ProgressBarView(value: 0.5)
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


