//
//  HeartView.swift
//  FloatingHeart
//
//  Created by Said Marouf on 9/22/15.
//  Copyright © 2015 Said Marouf. All rights reserved.
//

import UIKit
import Foundation

// MARK: Themes

public struct HeartTheme {
    let fillColor: UIColor
    let strokeColor: UIColor
    //using white borders for this example. Set your colors.
    static var availableThemes = [
        (UIColor(hex: 0xe66f5e), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0x6a69a0), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0x81cc88), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0xfd3870), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0x6ecff6), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0xc0aaf7), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0xf7603b), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0x39d3d3), UIColor(white: 1.0, alpha: 0.8)),
        (UIColor(hex: 0xfed301), UIColor(white: 1.0, alpha: 0.8))
    ]
    
    static func randomTheme() -> HeartTheme {
        let r = Int(randomNumber(availableThemes.count))
        let theme = availableThemes[r]
        return HeartTheme(fillColor: theme.0, strokeColor: theme.1)
    }
}

// MARK: HeartView

enum RotationDirection: CGFloat {
    case left = -1
    case right = 1
}

let PI = CGFloat(Double.pi)

open class HeartView: UIView {
    
    var imageString:String?
    
    fileprivate struct Durations {
        static let Full: TimeInterval = 4.0
        static let Bloom: TimeInterval = 0.5
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        layer.anchorPoint = CGPoint(x: 0.5, y: 1)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Animations
    
    open func animateInView(_ view: UIView) {
        guard let rotationDirection = RotationDirection(rawValue: CGFloat(1 - Int(2 * randomNumber(2)))) else { return }
        prepareForAnimation()
        performBloomAnimation()
        performSlightRotationAnimation(rotationDirection)
        addPathAnimation(inView: view)
    }
    
    open func setImageString(_ image: String) {
        print("string" , image)
        imageString = image
    }
    
    fileprivate func prepareForAnimation() {
        transform = CGAffineTransform(scaleX: 0, y: 0)
        alpha = 0
    }
    
    fileprivate func performBloomAnimation() {
        spring(duration: Durations.Bloom, delay: 0.0, damping: 0.6, velocity: 0.8) {
            self.transform = CGAffineTransform.identity
            self.alpha = 0.9
        }
    }
    
    fileprivate func performSlightRotationAnimation(_ direction: RotationDirection) {
        let rotationFraction = randomNumber(10)
        UIView.animate(withDuration: Durations.Full) {
            self.transform = CGAffineTransform(rotationAngle: direction.rawValue * PI / (16 + rotationFraction * 0.2))
                .scaledBy(x: 1.0 + rotationFraction/6.0, y: 1.0 + rotationFraction/6.0)
        }
    }
    
    fileprivate func travelPath(inView view: UIView) -> UIBezierPath? {
        guard let endPointDirection = RotationDirection(rawValue: CGFloat(1 - Int(2 * randomNumber(2)))) else { return nil }
        
        let heartCenterX = center.x
        let heartSize = bounds.width
        let viewHeight = view.bounds.height
        
        //random end point
        let endPointX = heartCenterX + (endPointDirection.rawValue * randomNumber(2 * heartSize))
        let endPointY = viewHeight / 8.0 + randomNumber(viewHeight / 4.0)
        let endPoint = CGPoint(x: endPointX, y: endPointY)
        
        //random Control Points
        let travelDirection = CGFloat(1 - Int(2 * randomNumber(2)))
        let xDelta = (heartSize / 2.0 + randomNumber(2 * heartSize)) * travelDirection
        let yDelta = max(endPoint.y ,max(randomNumber(8 * heartSize), heartSize))
        let controlPoint1 = CGPoint(x: heartCenterX + xDelta, y: viewHeight - yDelta)
        let controlPoint2 = CGPoint(x: heartCenterX - 2 * xDelta, y: yDelta)
        
        let path = UIBezierPath()
        path.move(to: center)
        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        return path
    }
    
    fileprivate func addPathAnimation(inView view: UIView) {
        guard let heartTravelPath = travelPath(inView: view) else { return }
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "position")
        keyFrameAnimation.path = heartTravelPath.cgPath
        keyFrameAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        let durationAdjustment = 4 * TimeInterval(heartTravelPath.bounds.height / view.bounds.height)
        let duration = Durations.Full + durationAdjustment
        keyFrameAnimation.duration = duration
        layer.add(keyFrameAnimation, forKey: "positionOnPath")
        
        animateToFinalAlpha(withDuration: duration)
    }
    
    fileprivate func animateToFinalAlpha(withDuration duration: TimeInterval = Durations.Full) {
        UIView.animate(withDuration: duration, delay: 0,
                       animations: {
                        self.alpha = 0.0
        },
                       completion: { _ in
                        self.removeFromSuperview()
        }
        )
    }
    //UIImag
    override open func draw(_ rect: CGRect) {
        let imageBundle = Bundle(for: HeartView.self)
        if let imageName = imageString {
            if let heartImage = UIImage(named: imageName, in: imageBundle, compatibleWith: nil) {
                let heartImageBorder = UIImage(named: "heartBorder", in: imageBundle, compatibleWith: nil)
                let theme = HeartTheme.randomTheme()
                //Draw background image (mimics border)
                theme.strokeColor.setFill()
                heartImageBorder?.draw(in: rect, blendMode: .normal, alpha: 1.0)
                
                //Draw foreground heart image
                theme.fillColor.setFill()
                heartImage.draw(in: rect, blendMode: .normal, alpha: 1.0)
            } else {
                //Just for fun. Draw heart using Bezier path
                drawHeartInRect(rect)
            }
        }
    }
    
    fileprivate func drawHeartInRect(_ rect: CGRect) {
        
        let theme = HeartTheme.randomTheme()
        
        theme.strokeColor.setStroke()
        theme.fillColor.setFill()
        
        let drawingPadding: CGFloat = 4.0
        let curveRadius = floor((rect.width - 2*drawingPadding) / 4.0)
        
        //Creat path
        let heartPath = UIBezierPath()
        
        //Start at bottom heart tip
        let tipLocation = CGPoint(x: floor(rect.width / 2.0), y: rect.height - drawingPadding)
        heartPath.move(to: tipLocation)
        
        //Move to top left start of curve
        let topLeftCurveStart = CGPoint(x: drawingPadding, y: floor(rect.height / 2.4))
        heartPath.addQuadCurve(to: topLeftCurveStart, controlPoint: CGPoint(x: topLeftCurveStart.x, y: topLeftCurveStart.y + curveRadius))
        
        //Create top left curve
        heartPath.addArc(withCenter: CGPoint(x: topLeftCurveStart.x + curveRadius, y: topLeftCurveStart.y), radius: curveRadius, startAngle: PI, endAngle: 0, clockwise: true)
        
        //Create top right curve
        let topRightCurveStart = CGPoint(x: topLeftCurveStart.x + 2*curveRadius, y: topLeftCurveStart.y)
        heartPath.addArc(withCenter: CGPoint(x: topRightCurveStart.x + curveRadius, y: topRightCurveStart.y), radius: curveRadius, startAngle: PI, endAngle: 0, clockwise: true)
        
        //Final curve to bottom heart tip
        let topRightCurveEnd = CGPoint(x: topLeftCurveStart.x + 4*curveRadius, y: topRightCurveStart.y)
        heartPath.addQuadCurve(to: tipLocation, controlPoint: CGPoint(x: topRightCurveEnd.x, y: topRightCurveEnd.y + curveRadius))
        
        heartPath.fill()
        
        heartPath.lineWidth = 1
        heartPath.lineCapStyle = .round
        heartPath.lineJoinStyle = .round
        heartPath.stroke()
    }
}
