//
//  ControlsViewController.swift
//  Example
//
//  Created by Vladislav Grigoryev on 18.11.2020.
//  Copyright © 2020 GORA Studio. https://gora.studio
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit
import SCNRecorder
import AVKit
import CoreLocation

protocol ControlsViewControllerDelegate: AnyObject {

  func controlsViewControllerDidTakePhoto(_ photo: UIImage)

  func controlsViewControllerDidTakeVideoAt(_ url: URL)
}

final class ControlsViewController: ViewController {

  // swiftlint:disable force_cast
  lazy var controlsView = view as! ControlsView
  // swiftlint:enable force_cast

  let viewController: ControllableViewController

  weak var delegate: ControlsViewControllerDelegate?

  lazy var durationBarButtonItem = UIBarButtonItem(
    title: nil,
    style: .plain,
    target: nil,
    action: nil
  )

  init(_ viewController: ControllableViewController) {
    self.viewController = viewController
    super.init()
  }

  override func loadView() { view = ControlsView() }

  override func viewDidLoad() {
    super.viewDidLoad()
    bindView()

    navigationItem.rightBarButtonItem = durationBarButtonItem

    addChild(viewController)
    controlsView.childView = viewController.view
    viewController.didMove(toParent: self)
  }

  func bindView() {
    controlsView.takePhoto = weakify(This.takePhoto)
    controlsView.startVideoRecording = weakify(This.startVideoRecording)
    controlsView.finishVideoRecording = weakify(This.finishVideoRecording)
  }

  func takePhoto() {
    controlsView.takePhotoButton.isEnabled = false
    controlsView.startVideoRecordingButton.isEnabled = false

    viewController.takePhoto { [weak self] (image) in
      guard let self = self else { return }

      DispatchQueue.main.async {
        self.delegate?.controlsViewControllerDidTakePhoto(image)

        self.controlsView.takePhotoButton.isEnabled = true
        self.controlsView.startVideoRecordingButton.isEnabled = true
      }
    }
  }
  
  private func createLocationMetadata(location: CLLocation) -> AVMetadataItem {
      let metadata = AVMutableMetadataItem()
      metadata.keySpace = AVMetadataKeySpace.quickTimeMetadata
      metadata.key = AVMetadataKey.quickTimeMetadataKeyLocationISO6709 as NSString
      metadata.identifier = AVMetadataIdentifier.quickTimeMetadataLocationISO6709
      metadata.value = String(format: "%+09.5f%+010.5f%+.0fCRSWGS_84", location.coordinate.latitude, location.coordinate.longitude, location.altitude) as NSString
      
     return metadata
  }

  func startVideoRecording() {
    do {
      let size = CGSize(width: 720, height: 1280)
      let location = CLLocation(latitude: 35.0, longitude: 135.0)
      let metadata:[AVMetadataItem] = [createLocationMetadata(location: location)]    // add location metadata
      let videoRecording = try viewController.startVideoRecording(size: size, metadata: metadata)

      let formatted: (TimeInterval) -> String = {
        let seconds = Int($0)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
      }

      videoRecording.$duration.observe(on: .main) { [weak self] in
        guard let self = self else { return }
        self.durationBarButtonItem.title = formatted($0)
      }

      durationBarButtonItem.title = formatted(videoRecording.duration)
      controlsView.takePhotoButton.isEnabled = false
      controlsView.startVideoRecordingButton.isHidden = true
      controlsView.finishVideoRecordingButton.isHidden = false
    }
    catch {
      print("Something went wrong during video-recording preparation: \(error)")
    }
  }

  func finishVideoRecording() {
    controlsView.finishVideoRecordingButton.isEnabled = false
    viewController.finishVideoRecording { [weak self] url in
      guard let self = self else { return }

      DispatchQueue.main.async {
        self.delegate?.controlsViewControllerDidTakeVideoAt(url)

        self.durationBarButtonItem.title = nil
        self.controlsView.takePhotoButton.isEnabled = true
        self.controlsView.startVideoRecordingButton.isHidden = false
        self.controlsView.finishVideoRecordingButton.isEnabled = true
        self.controlsView.finishVideoRecordingButton.isHidden = true
      }
    }
  }
}
