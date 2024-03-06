//
//  PhotoCloud.swift
//  HotOrBot
//
//  Created by Carlos on 3/6/24.
//

import SwiftUI

struct PhotoCloudItem: View {
    var image: SupabaseImage
    var dragThreshold: CGFloat
    var onRemove: (() -> Void)?
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isDragging = false
    @State private var dragAmount: CGSize = .zero

    var body: some View {
        AsyncSupabaseImage(image: image) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 80)
        } placeholder: {
            ZStack {
                Rectangle()
                    .frame(width: 60, height: 80)
                
                ProgressView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .rotationEffect(.degrees(rotation))
        .offset(x: offset.width + dragAmount.width, y: offset.height + dragAmount.height)
        .onAppear {
            startAnimation()
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.isDragging = true
                    self.dragAmount = gesture.translation
                }
                .onEnded { gesture in
                    if sqrt(gesture.translation.width * gesture.translation.width + gesture.translation.height * gesture.translation.height) > dragThreshold {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.dragAmount = gesture.predictedEndTranslation
                        }
                        
                        self.onRemove?()
                    } else {
                        withAnimation(.spring()) {
                            self.dragAmount = .zero
                        }
                    }
                    self.isDragging = false
                }
        )
    }

    func startAnimation() {
        withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            offset = CGSize(width: CGFloat.random(in: -10...10), height: CGFloat.random(in: -10...10))
            rotation = Double.random(in: -10...10)
        }
    }
}

struct PhotoCloud: View {
    var images: [SupabaseImage] = []
    var onImages: ([UIImage]) -> Void
    var onRemove: ((SupabaseImage) -> Void)?
    
    @State
    private var selectionState: PhotoSelectionButtonState = .empty
    @State
    private var cloudImages: [CloudImage] = []
    
    struct CloudImage: Equatable {
        var image: SupabaseImage
        var position: CGPoint
    }
    
    var body: some View {
        GeometryReader { geometry in
            let radius = geometry.size.width / 3
            
            ZStack {
                Circle()
                    .fill(Color(red: 246/256, green: 254/256, blue: 1.0))
                
                ZStack {
                    ForEach(Array(zip(cloudImages.indices, cloudImages)), id: \.1.image) { (i, image) in
                        PhotoCloudItem(image: image.image, dragThreshold: CGFloat(radius), onRemove: {
                            cloudImages.remove(at: i)
                            onRemove?(image.image)
                        })
                        .offset(x: image.position.x, y: image.position.y)
                    }
                    .transition(.asymmetric(insertion: .scale, removal: .slide))
                }
                .animation(.easeInOut, value: cloudImages)
                
                VStack {
                    PhotoSelectionButton(selectionState: $selectionState, maxSelectionCount: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                    } onImages: { images in
                        onImages(images)
                    }
                }
            }
            .onAppear {
                for image in images {
                    let point = randomPointOnCircle(points: cloudImages.map { $0.position }, radius: radius, margin: 20, spacing: 100)
                    cloudImages.append(CloudImage(image: image, position: point))
                }
            }
            .onChange(of: images) {
                for (i, image) in cloudImages.enumerated() {
                    if !images.contains(where: { $0 == image.image }) {
                        cloudImages.remove(at: i)
                    }
                }
                
                for image in images {
                    if !cloudImages.contains(where: { $0.image == image }) {
                        let point = randomPointOnCircle(points: cloudImages.map { $0.position }, radius: radius, margin: 20, spacing: 100)
                        cloudImages.append(CloudImage(image: image, position: point))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func randomPointOnCircle(points: [CGPoint], radius: Double, margin: Double, spacing initialSpacing: Double) -> CGPoint {
        let circleCenter = CGPoint(x: 0, y: 0)
        var failedAttempts = 0
        var spacing = initialSpacing

        func distanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> Double {
            let xDist = point1.x - point2.x
            let yDist = point1.y - point2.y
            return Double(sqrt((xDist * xDist) + (yDist * yDist)))
        }

        while true {
            let angle = Double.random(in: 0..<2*Double.pi)
            let randomRadius = Double.random(in: (radius - margin)...(radius + margin))
            let randomPoint = CGPoint(x: circleCenter.x + CGFloat(randomRadius * cos(angle)), y: circleCenter.y + CGFloat(randomRadius * sin(angle)))

            var isTooCloseToExistingPoint = false
            for point in points {
                if distanceBetweenPoints(point1: point, point2: randomPoint) < spacing {
                    isTooCloseToExistingPoint = true
                    break
                }
            }

            if isTooCloseToExistingPoint {
                failedAttempts += 1
                spacing = initialSpacing / ((Double(failedAttempts) * 0.01) + 1)
                continue
            }

            return randomPoint
        }
    }
}

#Preview {
    var images = [
        SupabaseImage(from: UIImage(named: "profile-photo-1")!),
        SupabaseImage(from: UIImage(named: "profile-photo-2")!),
        SupabaseImage(from: UIImage(named: "profile-photo-3")!)
    ]
    
    return PhotoCloud(images: images) { _ in } onRemove: { _ in print("removing") }
}
