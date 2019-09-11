//
//  CameraViewController.swift
//  Snapcat
//
//  Created by Sai Kambampati on 8/21/19.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit
import ARKit
import Vision

class CameraViewController: UIViewController {
    
    @IBOutlet var previewView: ARSCNView!
    var timer: Timer?
    var rectangleView = UIView()
    var humanLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        previewView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        previewView.session.run(configuration)
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.detectCat), userInfo: nil, repeats: true)
    }
    
    @objc func detectCat() {
        self.rectangleView.removeFromSuperview()
        guard let currentFrameBuffer = self.previewView.session.currentFrame?.capturedImage else { return }
        let image = CIImage(cvPixelBuffer: currentFrameBuffer)
        let detectAnimalRequest = VNRecognizeAnimalsRequest { (request, error) in
            DispatchQueue.main.async {
                if let result = request.results?.first as? VNRecognizedObjectObservation {
                    let cats = result.labels.filter({$0.identifier == "Cat"})
                    for cat in cats {
                        self.rectangleView = UIView(frame: CGRect(x: result.boundingBox.minX * self.previewView.frame.width, y: result.boundingBox.minY * self.previewView.frame.height, width: result.boundingBox.width * self.previewView.frame.width, height: result.boundingBox.height * self.previewView.frame.height))
                        
                        self.humanLabel.text = "👦"
                        self.humanLabel.font = UIFont.systemFont(ofSize: 70)
                        self.humanLabel.frame = CGRect(x: 0, y: 0, width: self.rectangleView.frame.width, height: self.rectangleView.frame.height)
                        
                        self.rectangleView.addSubview(self.humanLabel)
                        self.rectangleView.backgroundColor = .clear
                        self.previewView.insertSubview(self.rectangleView, at: 0)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image).perform([detectAnimalRequest])
        }
    }
    
    @IBAction func snap(_ sender: Any) {
        let currentFrame = previewView.snapshot()
        let vc = self.storyboard?.instantiateViewController(identifier: "Profile") as! CatProfileViewController
        vc.catImage = currentFrame
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        //translate camera frame to frame inside the ARSKView
        let origin = CGPoint(x: boundingBox.minX * previewView.bounds.width, y: (1 - boundingBox.maxY) * previewView.bounds.height)
        let size = CGSize(width: boundingBox.width * previewView.bounds.width, height: boundingBox.height * previewView.bounds.height)
        
        return CGRect(origin: origin, size: size)
    }
    
}

extension CameraViewController: ARSCNViewDelegate {
    
}
