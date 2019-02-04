//
// Copyright (c) 2018 Shakuro (https://shakuro.com/)
// Sergey Laschuk
//

import UIKit

class ImagePreviewViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var statusLabel: UILabel!

    private var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "image preview"
        updateImage()
    }

    private func setup(image aImage: UIImage?) {
        image = aImage
        if isViewLoaded {
            updateImage()
        }
    }

    private func updateImage() {
        imageView.image = image
        statusLabel.text = image == nil ? "no image" : nil
    }

}

extension ImagePreviewViewController {

    internal static func instantiate(image: UIImage?) -> UIViewController {
        let imageVC: ImagePreviewViewController = ExampleStoryboardName.main.storyboard().instantiateViewController(withIdentifier: "kImagePreviewViewControllerID")
        imageVC.setup(image: image)
        return imageVC
    }

}
