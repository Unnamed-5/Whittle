//
//  DrawingsViewController.swift
//  IvyControl
//
//  Created by RRRRR on 2021/8/3.
//

import UIKit
import CoreData

class DrawingsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let sectionInsets = UIEdgeInsets(
        top: 0,
        left: 8,
        bottom: 0,
        right: 8)

    private var itemsPerRow: CGFloat = 2
    
    var drawings = [Drawing]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.allowsMultipleSelection = false

        refreshItemsPerRow()
        
        refresh()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func newDrawing() {
        let setSizeVC = storyboard!.instantiateViewController(identifier: "SetSize")
        present(setSizeVC, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        drawings.count
    }
    
    // MARK: Configure Cells
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Drawing Cell", for: indexPath) as! DrawingCell
        cell.setup(withDrawing: drawings[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        sectionInsets
    }
    
    // MARK: Size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = (collectionView.frame.width  - (itemsPerRow + 2 * sectionInsets.left)) / itemsPerRow
        
        return CGSize(width: width, height: 1.5 * width)
    }
    
    // MARK: Selection
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! DrawingCell
        
        
        cell.drawingImageView.layer.borderWidth = 4
        cell.drawingImageView.layer.borderColor = UIColor.systemGreen.cgColor
        
        let canvasNav = storyboard!.instantiateViewController(withIdentifier: "CanvasNav") as! UINavigationController
        let canvasVC = canvasNav.viewControllers.first as! CanvasViewController
        
        canvasVC.drawing = drawings[indexPath.item]
        
        present(canvasNav, animated: true, completion: {
//            cell.backgroundColor = .clear
            cell.drawingImageView.layer.borderWidth = 1
            cell.drawingImageView.layer.borderColor = UIColor.systemGray4.cgColor
        })
        
        
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        (collectionView.cellForItem(at: indexPath) as! DrawingCell).backgroundColor = .clear
        
        (collectionView.cellForItem(at: indexPath) as! DrawingCell).drawingImageView.layer.borderWidth = 1
        (collectionView.cellForItem(at: indexPath) as! DrawingCell).drawingImageView.layer.borderColor = UIColor.systemGray4.cgColor

    }
    
    // MARK: Context Menu
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let actionProvider: UIContextMenuActionProvider = {
            _ in
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil"), handler: {
                _ in
                
                let renameAlert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
                
                renameAlert.addTextField(configurationHandler: { [self] in
                    $0.addTarget(self, action: #selector(checkRenameTextField), for: .editingChanged)
                    $0.addTarget(self, action: #selector(renameTextFieldBeginEditing), for: .editingDidBegin)
                    $0.text = drawings[indexPath.item].title
                })
                
                let renameAlertAction = UIAlertAction(title: "Rename", style: .default, handler: { [self] _ in
                    drawings[indexPath.item].title = renameAlert.textFields?.first?.text
                    appDelegate.saveContext()
                    collectionView.reloadItems(at: [indexPath])
                })
                renameAlertAction.isEnabled = false
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                renameAlert.addAction(cancelAction)
                renameAlert.addAction(renameAlertAction)
                
                renameAlert.view.tintColor = .systemGreen
                
                
                self.present(renameAlert, animated: true, completion: nil)
            })
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive, handler: { [self]
                _ in
                
                context.delete(drawings[indexPath.item])
                drawings.remove(at: indexPath.item)
                appDelegate.saveContext()
                
                collectionView.deleteItems(at: [indexPath])
            })
            
            
            return UIMenu(children: [renameAction, deleteAction])
        }
    
        return .init(identifier: indexPath.item as NSCopying, previewProvider: nil, actionProvider: actionProvider)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshItemsPerRow()

        traitCollection.performAsCurrent {
            for cell in collectionView.visibleCells as! [DrawingCell] {
                cell.drawingImageView.image = nil
            }
        }
        
        collectionView.reloadData()
        
        print("changed traitcollection")
    }
    
    func refreshItemsPerRow() {
        if traitCollection.horizontalSizeClass == .regular {
            itemsPerRow = 5
        } else {
            itemsPerRow = 2
        }
    }
    
    func refresh() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Drawing> = Drawing.fetchRequest()
        do {
            drawings = try context.fetch(fetchRequest)
        } catch _ {
            print("ERROR")
        }

        collectionView.reloadData()
        print("Data Reloaded.")
    }
    
    @objc func checkRenameTextField() {
//        print("rename textField content changed")
        let renameAlert = presentedViewController as! UIAlertController
        let textField = renameAlert.textFields!.first!
        renameAlert.actions[1].isEnabled = textField.text != ""
    }
    
    @objc func renameTextFieldBeginEditing() {
        let renameAlert = presentedViewController as! UIAlertController
        let textField = renameAlert.textFields!.first!
        let endPosition = textField.endOfDocument
        let startPosition = textField.position(from: endPosition, offset: -textField.text!.count)!
        textField.selectedTextRange = textField.textRange(from: startPosition, to: endPosition)
    }
}

