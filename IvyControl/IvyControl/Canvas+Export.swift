//
//  Canvas+Export.swift
//  IvyControl
//
//  Created by RRRRR on 2021/10/18.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import UIKit

extension CanvasViewController: UIDocumentInteractionControllerDelegate {
    
    enum BinarizationMethod {
        case fixedThreshold
        case dither
    }
    
    enum ExportWay {
        case previewImage
        case exportFile
        case sendToWall
    }
    
    func setupExportMenu() {
        let fixedThresholdFile = UIAction(
            title: "Export File",
            image: .init(systemName: "doc"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .fixedThreshold,
                    fileType: .exportFile
                )
            })
        
        let fixedThresholdSendToWall = UIAction(
            title: "Send To AuxWall",
            image: .init(systemName: "arrow.up.circle"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .fixedThreshold,
                    fileType: .sendToWall
                )
            })
        
        let fixedThresholdImage = UIAction(
            title: "Preview Image",
            image: .init(systemName: "photo"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .fixedThreshold,
                    fileType: .previewImage
                )
            })
        
        let fixedThresholdMenu = UIMenu(
            title: "Fixed Threshold",
            image: .init(systemName: "squareshape"),
            children: [fixedThresholdImage, fixedThresholdFile, fixedThresholdSendToWall]
        )
        
        
        let ditherFile = UIAction(
            title: "Export File",
            image: .init(systemName: "doc"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .dither,
                    fileType: .exportFile
                )
            })
        
        let ditherImage = UIAction(
            title: "Preview Image",
            image: .init(systemName: "photo"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .dither,
                    fileType: .previewImage
                )
            })
        
        let ditherSendToWall = UIAction(
            title: "Send To AuxWall",
            image: .init(systemName: "arrow.up.circle"),
            handler: { _ in
                self.export(
                    withBinarizationMethod: .dither,
                    fileType: .sendToWall
                )
            })
        
        let ditherMenu = UIMenu(
            title: "Dither",
            image: .init(systemName: "squareshape.split.3x3"),
            children: [ditherImage, ditherFile, ditherSendToWall]
        )
        
        let methodsMenu = UIMenu(
            options: .displayInline,
            children: [fixedThresholdMenu, ditherMenu]
        )
        
        let learnMore = UIAction(
            title: "Learn More...",
            image: .init(systemName: "questionmark.circle"),
            handler: { _ in
                let aboutAlert = UIAlertController(
                    title: "About Binarization Methods",
                    message: "Fixed Threshold: \nRecolor all pixels as pure black/white using the medium gray scale as a fixed dividing line, suitable for images with uniform grayscale.\n\nDithering: \nUsing \"dithering\" to mix black and white pixels to achieve the effect of more color, but with noise-like imperfections, suitable for images with greyscale hierarchies.",
                    preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                aboutAlert.addAction(okAction)
                aboutAlert.view.tintColor = .systemGreen
                self.present(aboutAlert, animated: true, completion: nil)
            })
        
        
        
        exportButton.menu = UIMenu(title: "Choose a Binarization Method",
                                   image: nil,
                                   identifier: nil,
                                   options: [],
                                   children: [methodsMenu, learnMore])
    }
    
    // MARK: Export
    
    func export(withBinarizationMethod method: BinarizationMethod, fileType: ExportWay) {
        
        if hasModifiedDrawing {
            drawing.data = canvasView.drawing.dataRepresentation()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.saveContext()
        }
        
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.startAnimating()
        exportButton.customView = activityIndicator
        
        let fileManager = FileManager.default
        var fileName = drawing.title!
        if fileType == .previewImage {
            fileName += ".png"
        }
        
        fileURL = fileManager.temporaryDirectory.appendingPathComponent(fileName)
        
        let rect = CGRect(
            origin: .zero,
            size: pixelSize
        )
        var image: UIImage!
        canvasView.traitCollection.performAsCurrent {
            image = canvasView.drawing.image(from: rect, scale: 1)
        }
        
        image = image.resized(
            to: image.size / canvasZoomScale
        )
        
        image = image.maskedWithColor(color: .white)
        
        switch method {
        case .fixedThreshold:
            image = image.binarized()
        case .dither:
            image = image.dithered()
        }
        
        switch fileType {
            
        case .previewImage:
            try! image.pngData()!.write(to: fileURL)
            
            let preview = UIDocumentInteractionController(url: fileURL)
            preview.delegate = self
            preview.name = drawing.title! + " Preview"
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            preview.presentPreview(animated: true)
            
        case .exportFile:
            
            let coordinates = coordinatesData(forImage: image)
            
            try! coordinates.write(to: fileURL, atomically: true, encoding: .utf8)
            
            let shareVC = UIActivityViewController(activityItems: [fileURL!], applicationActivities: nil)
            shareVC.popoverPresentationController?.barButtonItem = exportButton
            
            shareVC.completionWithItemsHandler = {
                _, completed, _, error in
                
                do {
                    try FileManager.default.removeItem(at: self.fileURL)
                } catch {}
                
                if error == nil {
                    if completed {
                        let alertController = UIAlertController(title: "Exported!", message: nil, preferredStyle: .alert)
                        alertController.view.tintColor = UIColor.label
                        self.present(alertController, animated: true, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                            self.presentedViewController!.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            
            shareVC.view.tintColor = .systemGreen
            
            
            self.present(shareVC, animated: true, completion: { [self] in
                activityIndicator.stopAnimating()
                exportButton.customView = nil
            })
            
        case .sendToWall:
            print("TODO: SEND TO AUXWALL")
            // TODO: Send to wall bluetooth part
            
        }
        
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        self
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {}
        
    }
    
    
    func documentInteractionControllerWillBeginPreview(_ controller: UIDocumentInteractionController) {
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        
        (exportButton.customView as! UIActivityIndicatorView).stopAnimating()
        exportButton.customView = nil
    }
    
    func coordinatesData(forImage image: UIImage) -> String {
        
        var pixels = [Int]()
        let colorsArray = image.pixelData()!
        for index in 1...colorsArray.count {
            if (index - 1) % 4 == 0 {
                if colorsArray[Int(index)] == 255 {
                    pixels.append(0)
                } else {
                    pixels.append(1)
                }
            }
        }
        
        
        print(colorsArray.count)
        
        print(pixels.count)
        
        var coordinates = ""
        
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let pixelNumber = width * height
        
        print(pixelNumber)
        
        for pixelIndex in 1 ... pixelNumber {
            if pixels[pixelIndex - 1] == 1 {
                var xCoordinate = pixelIndex % width
                if xCoordinate == 0 {
                    xCoordinate = width
                }
                
                var yCoordinate = pixelIndex / width
                if xCoordinate != width {
                    yCoordinate += 1
                }
                
                coordinates += "\(xCoordinate),\(yCoordinate)\n"
            }
        }
        coordinates.removeLast(2)
        
        return coordinates
    }
}
