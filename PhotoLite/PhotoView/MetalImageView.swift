//
//  MetalImageView.swift
//  PhotoView
//
//  Created by Suxin on 2024/4/3.
//

import Foundation
import SwiftUI
import Metal
import MetalKit
import CoreImage

let maxBuffersInFlight = 3

import Foundation

struct PolygonUniforms {
    let origin: SIMD2<Float>
    let screenWidth: Float
    let screenHeight: Float
    let numberOfSides: Float
    let radius: Float // In Pixels
    let isFilled: Bool // True means its fill (triangle strip), false means its outline.
}


class MetalViewModel: ObservableObject {
//    var image: CIImage?
    var sourceImage: CIImage?
    var drawableSize: CGSize?
    
    var scaleFactor: CGFloat = 1.1
    var anchorPoint: CGPoint = .zero
    
    var screenScaleFactor: CGFloat = 1
    
    var matrix: CGAffineTransform = .init(1, 0, 0, 1, 0, 0)
    
    var dragStartPoint: CGPoint = .zero
    
    var inited: Bool = false
    var modifiedByUser: Bool = false

    static let shared = MetalViewModel()
    
    var image: CIImage? {
        get {
            guard let image = sourceImage else {
                return nil
            }
            return image.transformed(by: matrix)
        }
    }
    
    init() {
        if let sf = NSScreen.main?.backingScaleFactor {
            screenScaleFactor = sf
        }
    }
    
    func setDrawableSize(size: CGSize) {
        drawableSize = size
        if (dragStartPoint == .zero) {
            anchorPoint = CGPoint(x: size.width / 2 , y: size.height / 2)
        }
    }
    
    func initImage(image: CIImage) {
        sourceImage = image
        matrix = .init(1, 0, 0, 1, 0, 0)
        
        inited = false
        modifiedByUser = false
    }
    
    func reset() {
        matrix = .init(1, 0, 0, 1, 0, 0)
        
        inited = false
        modifiedByUser = false
        initImageScale()
    }
    
    func initImageScale() {
        if (inited && modifiedByUser) {
            return
        }
        guard let image = sourceImage else {
            return
        }
        
        guard let size = drawableSize else {
            return
        }
        
        matrix = .init(1, 0, 0, 1, 0, 0)
        
        var renderImage = image

        let scaleX = size.width / renderImage.extent.width
        let scaleY = size.height / renderImage.extent.height
        let scale = min(scaleX, scaleY)
        renderImage = renderImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        self.scale(sx: scale, sy: scale)
        
        let originX = (size.width - renderImage.extent.size.width) / 2
        let originY = (size.height - renderImage.extent.size.height) / 2
        let pt = transformedPoint(x: originX, y: originY)
        self.translate(dx: pt.x, dy: pt.y)
        
        inited = true
//        self.sourceImage = renderImage
    }
    
    func zoom(steps: CGFloat) {
//        print(matrix)
        if (matrix.a < 0.2 && steps < 0) {
            return
        }
        if (matrix.a > 8 && steps > 0) {
            return
        }
        
        let pt = transformedPoint(x: anchorPoint.x, y: anchorPoint.y)
        translate(dx: pt.x, dy: pt.y)
        let factor = pow(1.1, steps)
        scale(sx: factor, sy: factor)
        translate(dx: -pt.x, dy: -pt.y)
        
        modifiedByUser = true
    }
    
    func move(current: CGPoint) {
        let stt = dragStartPoint
        let ct = localizedPoint(pt: current)
        let ctt = transformedPoint(x: ct.x, y: ct.y)
        
        translate(dx: ctt.x - stt.x, dy: ctt.y - stt.y)
        
        modifiedByUser = true
    }
    
    func moveByDelta(dx: CGFloat, dy: CGFloat) {
        translate(dx: dx * screenScaleFactor, dy: -dy * screenScaleFactor)
        modifiedByUser = true
    }
    
    func scale(sx: CGFloat, sy: CGFloat) {
        matrix = matrix.scaledBy(x: sx, y: sy)
    }
    
    func translate(dx: CGFloat, dy: CGFloat) {
        matrix = matrix.translatedBy(x: dx, y: dy)
    }
    
    func transformedPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        let point = CGPoint(x: x, y: y)
        return point.applying(matrix.inverted())
    }
    
    func setDragStart(pt: CGPoint) {
        let localPt = localizedPoint(pt: pt)
        dragStartPoint = transformedPoint(x: localPt.x, y: localPt.y)
    }
    

    
    func localizedPoint(pt: CGPoint) -> CGPoint {
        guard let size = drawableSize else {
            return pt
        }
        return CGPoint(x: pt.x * screenScaleFactor, y: size.height - (pt.y * screenScaleFactor))
    }
    
    func setAnchor(p: CGPoint) {
        let newAnchor = localizedPoint(pt: p)
        anchorPoint = newAnchor
    }
}

struct MetalImageView: ViewRepresentable {
    
    init(image: CIImage) {
        if (image == MetalViewModel.shared.sourceImage) {
            return
        }
        MetalViewModel.shared.initImage(image: image)
        MetalViewModel.shared.initImageScale()
    }

    func makeView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.colorPixelFormat = .rgba16Float
        metalView.framebufferOnly = false
        metalView.preferredFramesPerSecond = 60
        metalView.layerContentsPlacement = .center
        metalView.delegate = context.coordinator
        metalView.layer?.isOpaque = false
        metalView.layer?.wantsExtendedDynamicRangeContent = true
        
        return metalView
    }

    func updateView(_ uiView: MTKView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        let parent: MetalImageView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var ciContext: CIContext
        var model = MetalViewModel.shared
        var pipelineState: MTLRenderPipelineState!
        let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        let opaqueBackground = CIImage.white
        let clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        

        init(_ parent: MetalImageView) {
            self.parent = parent
            
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            self.ciContext = CIContext(mtlDevice: metalDevice, options: [.cacheIntermediates: false, .allowLowPower: true])
            
            super.init()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            MetalViewModel.shared.setDrawableSize(size: size)
            MetalViewModel.shared.initImageScale()
        }
        
//        func clear(in view: MTKView) {
//            print("clear meltal view")
//            guard let drawable = view.currentDrawable else {
//                return
//            }
//            let commandBuffer = metalCommandQueue.makeCommandBuffer()
//            let rpd = view.currentRenderPassDescriptor
//            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
//            rpd?.colorAttachments[0].loadAction = .clear
//            rpd?.colorAttachments[0].storeAction = .store
//            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
//
//            re?.endEncoding()
//            commandBuffer?.present(drawable)
//            commandBuffer?.commit()
//        }
        
        
        func drawIndicator(in view: MTKView) {
            
        }

        func draw(in view: MTKView) {
            _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
            let model = MetalViewModel.shared
            
            // initiate gpu rendering piplien state
            let defaultLibrary = view.device!.makeDefaultLibrary()
            let vertexFunction = defaultLibrary?.makeFunction(name: "polygon_vertex_main")
            let fragmentFunction = defaultLibrary?.makeFunction(name: "polygon_fragment_main")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            do {
                pipelineState = try view.device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                fatalError("Failed to create pipeline state: \(error)")
            }
            
            if let commandBuffer = metalCommandQueue.makeCommandBuffer() {
                view.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)
                let semaphore = inFlightSemaphore
                commandBuffer.addCompletedHandler { (_ commandBuffer) -> Swift.Void in
                    semaphore.signal()
                }
                
                guard let image = model.image else {
                    return
                }
                
                if let drawable = view.currentDrawable
                {
                    
                    let rpd = view.currentRenderPassDescriptor
                    rpd?.colorAttachments[0].clearColor = clearColor
                    rpd?.colorAttachments[0].loadAction = .clear
                    rpd?.colorAttachments[0].storeAction = .store
                    let re = commandBuffer.makeRenderCommandEncoder(descriptor: rpd!)
//                    drawPolygon(encoder: re!, numberOfSides: 5, x: 200, y: 200, radius: Float(250), isFilled: false, view: view)
                    re?.endEncoding()
                    
                    let renderImage = image
                    
//                    renderImage = renderImage.composited(over: self.opaqueBackground)
                    
                    guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3) else {return}
                    view.colorspace = colorSpace;
                    
                    let destination = CIRenderDestination(
                        width: Int(view.drawableSize.width),
                        height: Int(view.drawableSize.height),
                        pixelFormat: view.colorPixelFormat,
                        commandBuffer: commandBuffer,
                        mtlTextureProvider: {() -> MTLTexture in
                            return drawable.texture
                        }
                    )
                    

                    
                    
                    try! ciContext.startTask(toRender: renderImage, to: destination)
                    
                    
                    commandBuffer.present(drawable)
                    commandBuffer.commit()
//                    commandBuffer.waitUntilScheduled()
                }
            }
        }
        
        func drawPolygon(encoder: MTLRenderCommandEncoder, numberOfSides: Int, x: CGFloat, y: CGFloat, radius: Float, isFilled: Bool, view: MTKView) {
            let screenBounds = view.drawableSize
            
            let proportionalX = x / screenBounds.width
            let proportionalY = y / screenBounds.height
            
            let metalX: Float = Float(proportionalX * 2.0) - 1.0
            let metalY: Float = 1.0 - Float(proportionalY * 2.0)
            
            var uniforms: PolygonUniforms = PolygonUniforms(
                origin: SIMD2(x: metalX, y: metalY),
                screenWidth: Float(screenBounds.width),
                screenHeight: Float(screenBounds.height),
                numberOfSides: Float(numberOfSides),
                radius: radius, isFilled: isFilled
            )
            
            guard let uniformBuffer: MTLBuffer = metalDevice.makeBuffer(bytes: &uniforms, length: MemoryLayout<PolygonUniforms>.stride, options: []) else {
                return
            }
            
            uniformBuffer.label = "uniformsBuffer"
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 0)
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.drawPrimitives(
                type: uniforms.isFilled ? .triangle : .lineStrip,
                vertexStart: 0,
                vertexCount: uniforms.isFilled ? numberOfSides * 3 : numberOfSides + 1
            )
        }
    }
}
