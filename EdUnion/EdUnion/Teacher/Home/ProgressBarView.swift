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
                            .mainOrange
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

struct ContentView: View {
    @State private var progressValue = 0.5
    
    var body: some View {
        VStack {
            ProgressBarView(value: progressValue)
                .padding()
            
            Button(action: {
                withAnimation {
                    progressValue = Double.random(in: 0...1)
                }
            }) {
                Text("Change Progress")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
