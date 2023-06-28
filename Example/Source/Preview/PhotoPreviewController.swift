//
//  PhotoPreviewController.swift
//  Example
//
//  Created by Vladislav Grigoryev on 12/03/2019.
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
import CoreLocation

extension CLLocation {
    func exifMetadata(heading:CLHeading? = nil) -> NSMutableDictionary {

        let GPSMetadata = NSMutableDictionary()
        let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"

        // GPS metadata
        GPSMetadata[(kCGImagePropertyGPSLatitude as String)] = abs(self.coordinate.latitude)
        GPSMetadata[(kCGImagePropertyGPSLongitude as String)] = abs(self.coordinate.longitude)
        GPSMetadata[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
        GPSMetadata[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
        GPSMetadata[(kCGImagePropertyGPSAltitude as String)] = Int(abs(self.altitude))
        GPSMetadata[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
        GPSMetadata[(kCGImagePropertyGPSTimeStamp as String)] = self.timestamp.isoTime()
        GPSMetadata[(kCGImagePropertyGPSDateStamp as String)] = self.timestamp.isoDate()
        GPSMetadata[(kCGImagePropertyGPSVersion as String)] = "2.2.0.0"

        if let heading = heading {
            GPSMetadata[(kCGImagePropertyGPSImgDirection as String)] = heading.trueHeading
            GPSMetadata[(kCGImagePropertyGPSImgDirectionRef as String)] = "T"
        }

        return GPSMetadata
    }
}

extension Date {
    func isoDate() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "yyyy:MM:dd"
        return f.string(from: self)
    }

    func isoTime() -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: "UTC")
        f.dateFormat = "HH:mm:ss.SSSSSS"
        return f.string(from: self)
    }
}


final class PhotoPreviewController: ViewController {

  let photo: UIImage

  init(photo: UIImage) {
    self.photo = photo
    super.init()
  }

  override func loadView() {
    view = UIImageView(image: photo)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .action,
      target: self,
      action: #selector(share)
    )
  }
  
  private func createJPEGwithMetadata(jpeg: Data, properties:CFDictionary) -> Data {
      let src = CGImageSourceCreateWithData(jpeg as CFData, nil)!
      let uti = CGImageSourceGetType(src)!
      let jpegWithMetadata = NSMutableData()
      let dest = CGImageDestinationCreateWithData(jpegWithMetadata, uti, 1, nil)
      
      CGImageDestinationAddImageFromSource(dest!, src, 0, properties)
      if (CGImageDestinationFinalize(dest!)) {
          return jpegWithMetadata as Data
      } else {
          return Data()   // Error
      }
  }

  @objc func share() {

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.preferredRange = .extended
    format.opaque = true

    let data = photo.jpegData(compressionQuality: 1.0)!
    let location = CLLocation(latitude: 35.0, longitude: 135.0)
    let gpsMetadata = location.exifMetadata() //(exifMetadata is an extension
    let properties = [
        kCGImagePropertyGPSDictionary: gpsMetadata as Any
        // --(insert other dictionaries here if required)--
    ] as CFDictionary
    
    let dataWithMetadata = createJPEGwithMetadata(jpeg: data, properties: properties)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("photo.jpg")
    // try? data.write(to: url)
    try? dataWithMetadata.write(to: url)
    
    present(
      UIActivityViewController(activityItems: [url], applicationActivities: nil),
      animated: true,
      completion: nil
    )
  }
}
