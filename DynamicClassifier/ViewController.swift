//
//  ViewController.swift
//  DynamicClassifier
//
//  Created by Jiayue Zhang on 2018-02-26.
//  Copyright © 2018 Jiayue Zhang. All rights reserved.
//

import UIKit
import Vision
import CoreMedia
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate {
    // Outlets to label and view
    @IBOutlet private weak var predict: UILabel!
    @IBOutlet private weak var imageview: UIImageView!
    //@IBOutlet private weak var soundSwitch: UISwitch!
    @IBOutlet private weak var confidence: UILabel!
    @IBOutlet weak var switchButton: UIButton!
    
    //(frame: CGRect(x:0,y:0,width:200,height:50)
    var flag = 0
    var audioPlayer: AVAudioPlayer!
   /*
    switchLabel.textColor = UIColor.black
    switchLabel.backgroundColor = UIColor.white
    switchLabel.textAlignment = .center
    switchLabel.layer.cornerRadius = 10
    switchLabel.clipsToBounds = true
    */
   
    
    let model = MobileNet()
    //let model2 = GoogLeNetPlaces()
    let model2 = Food101()
    private var videoCapture: VideoCapture!
    private var requests = [VNRequest]()
    
    @IBAction func buttonTapped(_ switchButton: UIButton){
        if self.flag == 0 {
            self.flag = 1
        }
        else {
            self.flag = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let spec = VideoSpec(fps: 5, size: CGSize(width: 299, height: 299))
        videoCapture = VideoCapture(cameraType: .back,
                                    preferredSpec: spec,
                                    previewContainer: imageview.layer)
        
     
       //*  if there is switch button
        videoCapture.imageBufferHandler = {[unowned self] (imageBuffer) in
            
            if self.flag == 0 {
                //detect object
                self.handleImageBufferWithCoreML(imageBuffer: imageBuffer)
                
            }
            else{
                //detect food
                self.handleImageBufferWithSecML(imageBuffer: imageBuffer)}

        }
      
        
        //*/
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func playBgMusic(){
        let musicPath = Bundle.main.path(forResource: "cat", ofType: "mp3")
        let url = URL.init(fileURLWithPath: musicPath!)
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        }catch _ {
            audioPlayer = nil
        }
        //audioPlayer.numberOfLoops = 1
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    public func pauseBackgroundMusic() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
            }
        }
    }
    
    //Image CMSmapleBuffer to cvPixel
    func handleImageBufferWithCoreML(imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
            return
        }
        do {
            let prediction = try self.model.prediction(image: self.resize(pixelBuffer: pixelBuffer, size: 224)!)
            DispatchQueue.main.async {
                if let prob = prediction.classLabelProbs[prediction.classLabel] {
                    //self.predict.text = "\(prediction.classLabel) \(String(describing: prob))
                    if prediction.classLabel.contains("cat") {
                        //包含
                         self.playBgMusic()
                    }
                   // else {
                    //    self.pauseBackgroundMusic()
                    //}
                    self.predict.text = "\(prediction.classLabel)"
                    self.predict.textAlignment = .center
                    let prob = String(format:"%.2f",prob)
                    self.confidence.text = "confidence: \(String(describing: prob))"
                    self.confidence.textAlignment = .center
                   
                    
                   //&& self.soundSwitch.isOn
                }
            }
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
    
    func handleImageBufferWithSecML(imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
            return
        }
        do {
            let prediction = try self.model2.prediction(image: self.resize(pixelBuffer: pixelBuffer, size: 299)!)
            DispatchQueue.main.async {
                if let prob = prediction.foodConfidence[prediction.classLabel] {
                    //self.predict.text = "\(prediction.sceneLabel) \(String(describing: prob))"
                    self.predict.text = "\(prediction.classLabel)"
                    self.predict.textAlignment = .center
                    let prob = String(format:"%.2f",prob)
                    self.confidence.text = "confidence: \(String(describing: prob))"
                    self.confidence.textAlignment = .center
                }
            }
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
    
    
    //resize to 224x224 or 299x299
    func resize(pixelBuffer: CVPixelBuffer, size: Int) -> CVPixelBuffer? {
        let imageSide = size
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
        let ciContext = CIContext()
        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
        ciContext.render(ciImage, to: resizeBuffer!)
        return resizeBuffer
    }
    
    
    //orientation
    var exifOrientationFromDeviceOrientation: Int32 {
        let exifOrientation: DeviceOrientation
        enum DeviceOrientation: Int32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = .top0ColLeft
        case .landscapeRight:
            exifOrientation = .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        super.viewWillDisappear(animated)
    }
    



}

