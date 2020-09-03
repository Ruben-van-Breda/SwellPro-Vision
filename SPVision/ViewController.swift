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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var units_amount_TB: UITextField!
    @IBOutlet weak var itemText: UILabel!
    var ref: DatabaseReference!
    
    var itemString : String = "nothing"
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
        
            guard let results = finshedReq.results as? [VNClassificationObservation] else {return}
//            guard let firstObservation = results.first else {return}
            guard var firstObservation = results.first else {return}
        
            self.itemString = firstObservation.identifier.description
            DispatchQueue.main.async { // Correct
                self.itemText.text = "\(self.itemString) item"
            }
            print(self.itemString, firstObservation.confidence)
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer,options: [:]).perform([request])
    }

    @IBAction func BtnSubmit(_ sender: Any) {
        let item_amount = units_amount_TB.text?.description
       ref.child("Stock Item/\(itemString)/Units/").setValue(item_amount)
        
    }
}









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
