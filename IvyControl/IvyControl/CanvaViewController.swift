//
//  CanvasViewController.swift
//  IvyControl
//
//  Created by RRRRR on 2021/8/5.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import UIKit
import PencilKit

class CanvasViewController: UIViewController, PKToolPickerObserver, PKCanvasViewDelegate {
    
    @IBOutlet var canvasView: PKCanvasView!
    @IBOutlet var underlayView: UIView!
    
    var drawing: Drawing!
    
    var toolPicker: PKToolPicker!
    
    var drawingIndex: Int = 0
    var hasModifiedDrawing = false
    
    var fileURL: URL!
    
    @IBOutlet var undoButton: UIBarButtonItem!
    @IBOutlet var redoButton: UIBarButtonItem!
    @IBOutlet var exportButton: UIBarButtonItem!
    
    var pixelSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = drawing.title
        
        pixelSize = drawing.size * canvasZoomScale
        
        canvasView.contentSize = pixelSize
        canvasView.drawingPolicy = .default
        canvasView.minimumZoomScale = 0.1
        canvasView.maximumZoomScale = 100000
        canvasView.bouncesZoom = true
        canvasView.scrollsToTop = false
        
        canvasView.contentOffset = .zero
        
        underlayView.contentMode = .scaleToFill
        underlayView.frame = CGRect(origin: CGPoint.zero, size: pixelSize)
        underlayView.layer.shadowColor = UIColor.black.cgColor
        underlayView.layer.shadowOpacity = 0.3
        underlayView.layer.shadowRadius = 10
        underlayView.layer.shadowOffset = .zero
        
        setupExportMenu()
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        canvasView.delegate = self
        
        toolPicker = PKToolPicker()
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        
        canvasView.overrideUserInterfaceStyle = .light
        toolPicker.colorUserInterfaceStyle = .light
        
        canvasView.becomeFirstResponder()
        
        do {
            try canvasView.drawing = PKDrawing(data: drawing.data!)
        } catch _ { print("cannot get drawing from saved data")}
        
        canvasView.sendSubviewToBack(underlayView)
        
        updateLayout()
        
        exportButton.isEnabled = !canvasView.drawing.strokes.isEmpty
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if drawing.height < drawing.width {
            let canvasScale = canvasView.bounds.width / pixelSize.width
            canvasView.zoomScale = canvasScale
        } else {
            let canvasScale = canvasView.bounds.height / pixelSize.height
            canvasView.zoomScale = canvasScale
        }
        
        
    }

    
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        updateLayout()
    }
    
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        updateLayout()
    }
    
    // MARK: Update Layout
    func updateLayout() {
        
        let offsetX: CGFloat = max((canvasView.bounds.size.width - canvasView.contentSize.width) * 0.5, 0.0)
        let offsetY: CGFloat = max((canvasView.bounds.size.height - canvasView.contentSize.height) * 0.5, 0.0)
        
        underlayView.frame.size = pixelSize * canvasView.zoomScale
        
        canvasView.contentInset.left = offsetX
        
        let obscuredFrame = toolPicker.frameObscured(in: view)
        
        if obscuredFrame.isNull {
            print("floating tool picker")
            canvasView.horizontalScrollIndicatorInsets.bottom = 0
            canvasView.verticalScrollIndicatorInsets.bottom = 0
            navigationItem.setRightBarButtonItems([exportButton], animated: true)
        } else {
            
            print("compact tool picker")
            
            canvasView.horizontalScrollIndicatorInsets.bottom = obscuredFrame.height
            canvasView.verticalScrollIndicatorInsets.bottom = obscuredFrame.height
            navigationItem.setRightBarButtonItems([exportButton, redoButton, undoButton], animated: true)
        }
        
        canvasView.contentInset.top = offsetY
        canvasView.contentInset.bottom = offsetY + obscuredFrame.height
        
        underlayView.frame.inset(by: canvasView.contentInset)
        
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasModifiedDrawing = true
        exportButton.isEnabled = !canvasView.drawing.strokes.isEmpty
    }
    
    // MARK: did zoom
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        updateLayout()
    }
    
    @IBAction func done() {
        
        if hasModifiedDrawing {
            drawing.data = canvasView.drawing.dataRepresentation()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.saveContext()
        }
        let drawingsNav = presentingViewController as! UINavigationController
        let drawingsVC = drawingsNav.viewControllers.first as! DrawingsViewController
        let indexOfDrawing = drawingsVC.drawings.firstIndex(of: drawing)!
        drawingsVC.drawings[indexOfDrawing] = drawing
        drawingsVC.collectionView.reloadItems(at: [IndexPath(item: indexOfDrawing, section: 0)])
        dismiss(animated: true, completion: nil)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        underlayView
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let drawingsNav = presentingViewController as! UINavigationController
        let drawingsVC = drawingsNav.viewControllers.first as! DrawingsViewController
        drawingsVC.refresh()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}

