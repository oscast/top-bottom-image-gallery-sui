//
//  ContentView.swift
//  PhotoViewerSUI
//
//  Created by Oscar Castillo on 20/4/25.
//

import SwiftUI

// UIKit-based pinch-to-zoom for precise anchor zooming
import UIKit

class PinchZoomView: UIView {
    weak var delegate: PinchZoomViewDelgate?
    
    private(set) var scale: CGFloat = 0 {
        didSet { delegate?.pinchZoomView(self, didChangeScale: scale) }
    }
    private(set) var anchor: UnitPoint = .center {
        didSet { delegate?.pinchZoomView(self, didChangeAnchor: anchor) }
    }
    private(set) var offset: CGSize = .zero {
        didSet { delegate?.pinchZoomView(self, didChangeOffset: offset) }
    }
    private(set) var isPinching: Bool = false {
        didSet { delegate?.pinchZoomView(self, didChangePinching: isPinching) }
    }
    private var startLocation: CGPoint = .zero
    private var location: CGPoint = .zero
    private var numberOfTouches: Int = 0
    
    init() {
        super.init(frame: .zero)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            startLocation = gesture.location(in: self)
            anchor = UnitPoint(x: startLocation.x / bounds.width, y: startLocation.y / bounds.height)
            numberOfTouches = gesture.numberOfTouches
        case .changed:
            if gesture.numberOfTouches != numberOfTouches {
                let newLocation = gesture.location(in: self)
                let jumpDifference = CGSize(width: newLocation.x - location.x, height: newLocation.y - location.y)
                startLocation = CGPoint(x: startLocation.x + jumpDifference.width, y: startLocation.y + jumpDifference.height)
                numberOfTouches = gesture.numberOfTouches
            }
            scale = gesture.scale
            location = gesture.location(in: self)
            offset = CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        case .ended, .cancelled, .failed:
            withAnimation(.interactiveSpring()) {
                isPinching = false
                scale = 1.0
                anchor = .center
                offset = .zero
            }
        default:
            break
        }
    }
}

protocol PinchZoomViewDelgate: AnyObject {
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint)
    func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize)
}

struct PinchZoom: UIViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var offset: CGSize
    @Binding var isPinching: Bool
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> PinchZoomView {
        let pinchZoomView = PinchZoomView()
        pinchZoomView.delegate = context.coordinator
        return pinchZoomView
    }
    func updateUIView(_ pageControl: PinchZoomView, context: Context) { }
    class Coordinator: NSObject, PinchZoomViewDelgate {
        var pinchZoom: PinchZoom
        init(_ pinchZoom: PinchZoom) { self.pinchZoom = pinchZoom }
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangePinching isPinching: Bool) { pinchZoom.isPinching = isPinching }
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeScale scale: CGFloat) { pinchZoom.scale = scale }
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeAnchor anchor: UnitPoint) { pinchZoom.anchor = anchor }
        func pinchZoomView(_ pinchZoomView: PinchZoomView, didChangeOffset offset: CGSize) { pinchZoom.offset = offset }
    }
}

struct PinchToZoom: ViewModifier {
    @State var scale: CGFloat = 1.0
    @State var anchor: UnitPoint = .center
    @State var offset: CGSize = .zero
    @State var isPinching: Bool = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .offset(offset)
            .overlay(PinchZoom(scale: $scale, anchor: $anchor, offset: $offset, isPinching: $isPinching))
    }
}
extension View {
    func pinchToZoom() -> some View {
        self.modifier(PinchToZoom())
    }
}

struct ZoomableImage: View {
    let image: Image
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .pinchToZoom()
    }
}


struct ContentView: View {
    @State private var selectedImageIndex = 0
    // Replace these with your actual images
    let images: [Image] = [
        Image("IMG_6765"),
        Image("IMG_6783"),
        Image("IMG_6784"),
        Image("IMG_6785"),
        Image("IMG_6802"),
        Image("IMG_6803")
    ]
    
    // Layout variables for easy tweaking
    let mainImageFraction: CGFloat = 0.75
    let collectionFraction: CGFloat = 0.25
    let sectionSpacing: CGFloat = 0.0
    let thumbnailSpacing: CGFloat = 6.0
    let thumbnailCornerRadius: CGFloat = 6.0
    let thumbnailBorderWidth: CGFloat = 3.0

    
    /// Main layout for the Photo Viewer app.
    /// - Uses GeometryReader to adapt to device size and safe areas.
    /// - Top section: Zoomable main image (fills all available space)
    /// - Bottom section: Horizontal thumbnail bar (fixed height)
    /// - No Spacer between sections so they are always flush.
    /// - Thumbnail bar scrolls to selected image when changed.
    /// - UIKit is used for zooming (see ZoomableImage) for advanced gesture support.
    var body: some View {
        GeometryReader { geo in

            let thumbnailBarHeight = geo.size.height * collectionFraction
            VStack(spacing: sectionSpacing) {
                // Main image section (fills available space)
                MainPhotoSection(
                    images: images,
                    selectedImageIndex: $selectedImageIndex
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Thumbnail bar (fixed height, flush to bottom)
                ThumbnailBarSection(
                    images: images,
                    selectedImageIndex: $selectedImageIndex,
                    thumbnailBarHeight: thumbnailBarHeight,
                    thumbnailSpacing: thumbnailSpacing,
                    thumbnailCornerRadius: thumbnailCornerRadius,
                    thumbnailBorderWidth: thumbnailBorderWidth
                )
                .frame(height: thumbnailBarHeight)
            }
            .edgesIgnoringSafeArea(.horizontal)
            .background(Color.black)
        }
    }
    
    // MARK: - Modular Sections
    
    /// Displays the main (zoomable) photo area.
    /// - Uses TabView for paging between images.
    /// - Uses ZoomableImage, which relies on UIKit for advanced pinch-to-zoom and pan gestures (not natively available in SwiftUI).
    struct MainPhotoSection: View {
        let images: [Image]
        @Binding var selectedImageIndex: Int
        var body: some View {
            GeometryReader { geo in
                TabView(selection: $selectedImageIndex) {
                    ForEach(images.indices, id: \ .self) { idx in
                        ZoomableImage(image: images[idx])
                            .tag(idx)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .clipped()
            }
            .background(Color.black)
        }
    }
    
    /// Displays the horizontal thumbnail bar.
    /// - Uses ScrollViewReader to allow programmatic scrolling.
    /// - Automatically scrolls to center the selected thumbnail when the main photo changes.
    /// - Tapping a thumbnail updates the main photo.
    struct ThumbnailBarSection: View {
        let images: [Image]
        @Binding var selectedImageIndex: Int
        let thumbnailBarHeight: CGFloat
        let thumbnailSpacing: CGFloat
        let thumbnailCornerRadius: CGFloat
        let thumbnailBorderWidth: CGFloat
        
        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: thumbnailSpacing) {
                        ForEach(images.indices, id: \ .self) { idx in
                            images[idx]
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(width: thumbnailBarHeight * 0.9, height: thumbnailBarHeight * 0.9)
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: thumbnailCornerRadius)
                                        .stroke(selectedImageIndex == idx ? Color.blue : Color.clear, lineWidth: thumbnailBorderWidth)
                                )
                                .id(idx)
                                .onTapGesture {
                                    withAnimation {
                                        selectedImageIndex = idx
                                    }
                                }
                        }
                    }
                }
                // This ensures that whenever the selectedImageIndex changes (by swipe or tap),
                // the thumbnail bar scrolls to center the selected thumbnail.
                .onChange(of: selectedImageIndex) { _, idx in
                    withAnimation {
                        proxy.scrollTo(idx, anchor: .center)
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
}
