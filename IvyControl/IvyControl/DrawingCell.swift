//
//  DrawingCell.swift
//  IvyControl
//
//  Created by RRRRR on 2021/8/4.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import UIKit
import PencilKit

class DrawingCell: UICollectionViewCell {
    
    @IBOutlet var drawingImageView: UIImageView!
    @IBOutlet var drawingTitle: UILabel!
    @IBOutlet var drawingSubtitle: UILabel!
    
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    
    func setup(withDrawing drawing: Drawing? = nil) {
        layer.cornerRadius = 15
        layer.cornerCurve = .continuous
        
        drawingImageView.layer.cornerCurve = .continuous
        drawingImageView.layer.borderColor = UIColor.systemGray4.cgColor
        drawingImageView.isUserInteractionEnabled = true
        drawingImageView.overrideUserInterfaceStyle = .light
        
        drawingTitle.text = drawing?.title
        drawingSubtitle.text = "\(drawing!.width / 5) × \(drawing!.height / 5)"
        
        let thumbnailRect = CGRect(x: 0, y: 0, width: CGFloat(drawing!.width), height: CGFloat(drawing!.height))
        
    
        
        thumbnailQueue.async {
            
            DispatchQueue.main.async { [self] in
                drawingImageView.traitCollection.performAsCurrent {
                    do {
                        var image = try PKDrawing(data: drawing!.data!).image(from: thumbnailRect, scale: 1)
                        
                        let aspectRatio = image.size.width / image.size.height
                        
                        let imageViewSize = drawingImageView.frame.size
                        
                        var sizeToResize = CGSize(
                            width: imageViewSize.width,
                            height: imageViewSize.width / aspectRatio)
                        
                        // if the image is "higher" vertically
                        if drawing!.height > drawing!.width {
                            sizeToResize = .init(
                                width: imageViewSize.height * aspectRatio,
                                height: imageViewSize.height)
                        }
                        
                        image = image.resized(to: sizeToResize)
                        image = image.maskedWithColor(color: .white)
                        
                        DispatchQueue.main.async { [self] in
                            
                            drawingImageView.contentMode = .scaleAspectFit
                            drawingImageView.layer.masksToBounds = true
                            
                            drawingImageView.image = image
                            
                        }
                    } catch _ {}
                    
                }
            }
        }
        
    }
    
}
