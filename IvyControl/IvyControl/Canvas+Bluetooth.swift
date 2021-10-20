//
//  Canvas+Bluetooth.swift
//  IvyControl
//
//  Created by RRRRR on 2021/10/19.
//  Copyright © 2021 iGEM Whittle. All rights reserved.
//

import UIKit
import CoreBluetooth

extension CanvasViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Is Powered Off.")
        case .poweredOn:
            print("Is Powered On.")
        case .unsupported:
            print("Is Unsupported.")
        case .unauthorized:
            print("Is Unauthorized.")
        case .unknown:
            print("Unknown")
        case .resetting:
            print("Resetting")
        @unknown default:
            print("Error")
        }
    }
    
    
    // MARK: Discovered Wall
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager.stopScan()
        print("discovered Wall")
        
        auxWallPeripheral = peripheral
        
        auxWallPeripheral.delegate = self
        
        print("Peripheral Discovered: \(peripheral)")
        print("Peripheral name: " + peripheral.name!)
        print ("Advertisement Data : \(advertisementData)")
        
        
        presentedViewController!.dismiss(animated: true, completion: { [self] in
            let connectingAlert = UIAlertController(title: "AuxWall Discovered!", message: "Connecting...", preferredStyle: .alert)
            connectingAlert.view.tintColor = .systemGreen
            let cancelAction = UIAlertAction(title: "Cancel Connection", style: .cancel, handler: { [self] _ in
                centralManager.cancelPeripheralConnection(peripheral)
                exportButton.customView = nil
            })
            connectingAlert.addAction(cancelAction)
            present(connectingAlert, animated: true, completion: {
                centralManager?.connect(auxWallPeripheral, options: nil)
            })
            
        })
        
    }
    
    // MARK: Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Did connect")
        auxWallPeripheral.discoverServices([CBUUIDs.serviceUUID])
    }
    
    // MARK: Service Discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        print("Discovered Services: \(services)")

    }
    
    
    
    // MARK: Discovered Char, Send Data
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        presentedViewController!.dismiss(animated: true, completion: { [self] in
            let sendingAlert = UIAlertController(title: "AuxWall Connected!", message: "Sending Data...", preferredStyle: .alert)
            sendingAlert.view.tintColor = .systemGreen
            let cancelAction = UIAlertAction(title: "Cancel Send", style: .cancel, handler: { [self] _ in
                centralManager.cancelPeripheralConnection(auxWallPeripheral)
                exportButton.customView = nil
            })
            sendingAlert.addAction(cancelAction)
            present(sendingAlert, animated: true, completion: {
                guard let characteristics = service.characteristics else {
                    return
                }
                
                print("Found \(characteristics.count) characteristics.")
                
                for characteristic in characteristics {
                    print(characteristic)
                    if characteristic.uuid.isEqual(CBUUIDs.characterisitcUUID) {
                        
                        bluetoothCharacteristic = characteristic
                        
                        if let peripheral = auxWallPeripheral {
                            
                            if let characteristic = bluetoothCharacteristic {
                                peripheral.writeValue(dataToSend, for: characteristic, type: CBCharacteristicWriteType.withResponse)
                            
                            }
                        }
                    }
                }
            })
            
            
        })
        
        
    }
    
    // MARK: Did write value
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        exportButton.customView = nil
        
        if error == nil {
            print("did write value")
            centralManager.cancelPeripheralConnection(auxWallPeripheral)
            presentCompleteAlert()
        } else {
            print(error!)
            presentErrorAlert()()
        }
    }
    
    
    // MARK: Start Scanning
    func exportForBluetooth() {
        centralManager?.scanForPeripherals(withServices: [CBUUIDs.serviceUUID])
        let scanningAlert = UIAlertController(title: "Scanning for AuxWall Nearby...", message: nil, preferredStyle: .alert)
        scanningAlert.view.tintColor = .systemGreen
        let cancelAction = UIAlertAction(title: "Cancel Scanning", style: .cancel, handler: { [self] _ in
            centralManager.stopScan()
            exportButton.customView = nil
        })
        scanningAlert.addAction(cancelAction)
        present(scanningAlert, animated: true)
    }
    
    func presentErrorAlert() {
        presentedViewController?.dismiss(animated: true, completion: { [self] in
            let errorAlert = UIAlertController(title: "Error", message: "Some errors occured.", preferredStyle: .alert)
            errorAlert.view.tintColor = .systemGreen
            let okAction = UIAlertAction(title: "Okay", style: .cancel, handler: { [self] _ in
                if let peripheral = auxWallPeripheral {
                    centralManager.cancelPeripheralConnection(peripheral)
                }
                exportButton.customView = nil
            })
            errorAlert.addAction(okAction)
            present(errorAlert, animated: true)
        })
    }
    
    func presentCompleteAlert() {
        presentedViewController?.dismiss(animated: true, completion: { [self] in
            let completedAlert = UIAlertController(title: "Sent", message: "The data was sent to AuxWall.", preferredStyle: .alert)
            
            completedAlert.view.tintColor = .systemGreen
            let okAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            
            completedAlert.addAction(okAction)
            present(completedAlert, animated: true)
        })
    }
}
