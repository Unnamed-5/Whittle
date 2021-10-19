//
//  SetSizeViewController.swift
//  IvyControl
//
//  Created by RRRRR on 2021/8/5.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import UIKit
import PencilKit

class SetSizeViewController: UIViewController {

    @IBOutlet var widthTextField: UITextField!
    @IBOutlet var heightTextField: UITextField!
    
    @IBOutlet var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        widthTextField.delegate = self
        // Do any additional setup after loading the view.
        createButton.backgroundColor = .systemFill
        
        if #available(iOS 15, *) {
            sheetPresentationController?.detents = [.medium(), .large()]
            sheetPresentationController?.prefersGrabberVisible = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        widthTextField.becomeFirstResponder()
    }
    
    @IBAction func widthChanged() {
        if widthTextField.text! == ""  {
            createButton.isEnabled = false
            createButton.backgroundColor = .systemFill
        } else {
            createButton.isEnabled = true
            createButton.backgroundColor = .systemGreen
        }
    }
    
    @IBAction func createCanvas() {
        let homePage = self.presentingViewController as! UINavigationController
        self.dismiss(animated: true, completion: { [self] in
            let canvasNav = self.storyboard!.instantiateViewController(withIdentifier: "CanvasNav") as! UINavigationController
            let canvasVC = canvasNav.viewControllers.first as! CanvasViewController
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let newDrawing = Drawing(context: context)
            newDrawing.title = "Untitled"
            newDrawing.width = Int64(widthTextField.text!)! * 5
            newDrawing.height = Int64(heightTextField.text!)! * 5
            newDrawing.data = PKDrawing().dataRepresentation()
            canvasVC.drawing = newDrawing
            appDelegate.saveContext()
            let drawingsVC = homePage.viewControllers.first as! DrawingsViewController
            drawingsVC.drawings.append(newDrawing)
            let indexPath = IndexPath(item: drawingsVC.drawings.count - 1, section: 0)
            drawingsVC.collectionView.insertItems(at: [indexPath])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                drawingsVC.collectionView(drawingsVC.collectionView, didSelectItemAt: indexPath)
            })
            
            
        })
    }
    
    
    
    @IBAction func close() {
        
        dismiss(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SetSizeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let numbers = NSCharacterSet(charactersIn: "0123456789").inverted
        let filtered = (string.components(separatedBy: numbers) as NSArray).componentsJoined(by: "")
        return string == filtered
    }
    
    
}
