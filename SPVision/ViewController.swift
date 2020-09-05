//
//  ViewController.swift
//  SPVision
//
//  Created by Ruben van Breda on 2020/09/03.
//  Copyright © 2020 Ruben van Breda. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision
import FirebaseDatabase
import BLTNBoard

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var units_amount_TB: UITextField!
    @IBOutlet weak var itemText: UILabel!
    
    public var hasSelectedItem = false
    var ref: DatabaseReference!
    
    var itemString : String = "Place item in frame."
    var finalItemString : String = ""
    var isShowingCard = false
    
    var current_amount_stock : String = ""
    
    lazy var bulletinManager: BLTNItemManager = {
        let rootItem: BLTNPageItem = BLTNPageItem(title: "")
        return BLTNItemManager(rootItem: rootItem)
    }()
    private lazy var boardManager : BLTNItemManager = {
        
        let page = BLTNPageItem(title: "\(self.itemString)")
        page.image = UIImage(named: "barcode.png")
        page.actionButtonTitle = "Continue"
        page.alternativeButtonTitle = "Cancel"
        page.descriptionText = "Would you like to add qnty to \(self.itemString)"
        
        page.actionHandler = { _ in
            print("tapped continue")
            self.boardManager.dismissBulletin(animated: false)
        }
        page.alternativeHandler = { _ in
            print("tapped cancel")
            self.boardManager.dismissBulletin(animated: false)
        }
        page.appearance.actionButtonColor = .red
        self.boardManager.backgroundViewStyle = .dimmed
        let rootItem: BLTNItem = page
        return BLTNItemManager(rootItem: rootItem)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        //Here we start up the camera
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput) // monitor image frames
        
        
        
        // Firebase
        ref = Database.database().reference()
        
        
  
        
       
    
    }
    
    //each frame that is capture
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("Camera captured frame ", Date())
        guard let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: ImageClassifier().model) else {return}
        let request = VNCoreMLRequest(model: model)
        { (finshedReq, err) in
            
            var _hasSelectedItem = false
            guard let results = finshedReq.results as? [VNClassificationObservation] else {return}
//            guard let firstObservation = results.first else {return}
            
            guard var firstObservation = results.first else {return}
            
            
            if(firstObservation.confidence > 0.98 && self.hasSelectedItem == false){
                self.itemString = firstObservation.identifier.description
                _hasSelectedItem = true
            }
            
            if(firstObservation.confidence <= 0.90 && self.hasSelectedItem == true){
                self.itemString = "Place item in frame."
                _hasSelectedItem = false
                
            }
         
            DispatchQueue.main.async { // Correct
                if(self.isShowingCard == false){
                    self.itemText.text = "\(self.itemString)"
                    self.hasSelectedItem = _hasSelectedItem
                    if(_hasSelectedItem == true){
                        self.finalItemString = self.itemString
                        self.promptForAnswer()
                    }else{
                        
                    }
                }
            }
            
            
          
//            print(self.itemString, firstObservation.confidence)
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer,options: [:]).perform([request])
    }

    @IBAction func BtnSubmit(_ sender: Any) {
        let item_amount = units_amount_TB.text?.description
       ref.child("\(itemString)/QNT/").setValue(item_amount)
        
    }
    
    func ShowAlert(){
        let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func ShowSuccessCard(){
        DispatchQueue.main.async {
           
            let alert = UIAlertController(title: "Successfully Updated.", message: "\(self.finalItemString) has been updated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
                alert.dismiss(animated: true) {
                    self.isShowingCard = false
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func ShowActionsheet(){
        let actionsheet = UIAlertController(title: "\(self.itemString)", message: "Enter QNTY:", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
         NSLog("The \"OK\" alert occured.")
         }))
        actionsheet.addAction(.init(title: "WHat", style: .destructive, handler: { (_) in
        
        }))
        
        self.present(actionsheet, animated: true, completion: nil)
    }
    
    func promptForAnswer() {
        
   
        let lb : String = finalItemString.description
        SetCurrentStock(forKey: lb)
        
        let msg = "Currently in stock: \(current_amount_stock)"

        let ac = UIAlertController(title: "\(lb)", message: msg, preferredStyle: .alert)
        ac.addTextField()
        
        
        let addAction = UIAlertAction(title: "+", style: .default) { [unowned ac] _ in
                   let answer = ac.textFields![0]
                   DispatchQueue.main.async { // Correct
                    self.SetCurrentStock(forKey: "\(lb)")
                    guard let appendAm = try? Int(answer.text!) else{return}
                    guard let curAm = try? Int(self.current_amount_stock) else {return}
                    let newAm = curAm + appendAm
                    let valueString = "\(newAm)"
                    self.UpdateFirebase(value: valueString.description, key: lb)
                     self.isShowingCard = false
                   }
                   
               }
        let subtractAction = UIAlertAction(title: "-", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            DispatchQueue.main.async { // Correct
             self.SetCurrentStock(forKey: "\(lb)")
             guard let appendAm = try? Int(answer.text!) else{return}
             guard let curAm = try? Int(self.current_amount_stock) else {return}
             let newAm = curAm - appendAm
             let valueString = "\(newAm)"
             self.UpdateFirebase(value: valueString.description, key: lb)
                 self.isShowingCard = false
            }
            
        }
        let submitAction = UIAlertAction(title: "Reset", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            DispatchQueue.main.async { // Correct
                self.UpdateFirebase(value: answer.text!, key: lb)
                 self.isShowingCard = false
            }
            
        }
        let cancelAction = UIAlertAction(title: "Rescan", style: .default) { [unowned ac] _ in
            ac.dismiss(animated: true, completion: {})
             self.isShowingCard = false
        }
        ac.textFields![0].placeholder = "Enter quantity"
        ac.textFields![0].keyboardType = .numberPad
        
        ac.addAction(addAction)
        ac.addAction(subtractAction)
        ac.addAction(submitAction)
        ac.addAction(cancelAction)
        
        
        present(ac, animated: true)
        self.isShowingCard = true
    }
    func ShowBottomCard(){
        boardManager.prepareForInterfaceBuilder()
        boardManager.showBulletin(above: self)
       
    }
    
    func UpdateFirebase(value: String, key: String){
         
        self.ref.child("\(key)/QNTY/").setValue(value) { (error, dbreference) in
            if error != nil{
                print(error?.localizedDescription)


            } else {
                print("success", dbreference)
                self.ShowSuccessCard()

            }
        }
        
        
        
    }
   
    func SetCurrentStock(forKey: String) {
        var string = "null"
        self.ref.child("\(forKey)").observeSingleEvent(of: .value, with: { (snapshot) in
            if let data = snapshot.value as? [String : Any]{
                print(data["QNTY"] as? String ?? "")
                self.current_amount_stock = data["QNTY"] as? String ?? ""
                
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
            
        }
        
    }
    func showDynamicBulletin(dynamicTitle: String, dynamicDescription: String) {
        bulletinManager.prepareForInterfaceBuilder()
        self.isShowingCard = true
        
        let page = BLTNPageItem(title: dynamicTitle)
        page.descriptionText = dynamicDescription
        
        page.actionButtonTitle = "Done"
        page.actionHandler = { (item: BLTNActionItem) in
             self.bulletinManager.dismissBulletin()
        }
        page.alternativeButtonTitle = "Skip"
        page.alternativeHandler = { (item: BLTNActionItem) in
            self.isShowingCard = false
            self.bulletinManager.dismissBulletin()
        }
        
        bulletinManager = BLTNItemManager(rootItem: page)
        bulletinManager.backgroundViewStyle = .dimmed
        
        bulletinManager.showBulletin(above: self)
       
    }
    
    
    
   
    

    
    
}

//







// Put this piece of code anywhere you like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
