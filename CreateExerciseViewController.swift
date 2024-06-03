//
//  DatabaseProtocol.swift
//  FIT3178-W04-Lab
//
//  Created by Jason Haasz on 4/1/2023.
//

import UIKit

protocol AddCreateExerciseDelegate: AnyObject {
    func didAddExercise(_ exercise: Exercise)
}

class CreateExerciseViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var equipmentTextField: UITextField!
    @IBOutlet weak var bodyPartSegmentedControl: UISegmentedControl!
    @IBOutlet weak var gifUrlImageView: UIImageView!
    @IBOutlet weak var targetTextField: UITextField!
    @IBOutlet weak var secondaryMusclesTextField: UITextField!

    @IBOutlet weak var instructionsTextViewField: UITextField!
    weak var  addCreateExerciseDelegate :AddCreateExerciseDelegate?
    weak var databaseController: DatabaseProtocol?
    var gifUrl: URL?

    
    init(databaseController: DatabaseProtocol, delegate: AddCreateExerciseDelegate) {
        self.databaseController = databaseController
        self.addCreateExerciseDelegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        

    }

    @IBAction func createExercise(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let equipment = equipmentTextField.text, !equipment.isEmpty else {
            displayMessage(title: "Incomplete Fields", message: "Please ensure the required fields are filled.")
            return
        }

        let bodyPartIndex = bodyPartSegmentedControl.selectedSegmentIndex
        let bodyPart = bodyPartSegmentedControl.titleForSegment(at: bodyPartIndex) ?? ""

        let target = targetTextField.text ?? ""
        let secondaryMuscles = secondaryMusclesTextField.text ?? ""
        let instructions = instructionsTextViewField.text ?? ""
        guard let gifUrlString = gifUrl?.absoluteString ?? Bundle.main.path(forResource: "Image", ofType: "jpg") else { return }

        let newExercies = databaseController?.addExercise(name: name,
                                                bodyPart: bodyPart,
                                                equipment: equipment,
                                                gifUrl: gifUrlString,
                                                target: target,
                                                secondaryMuscles: secondaryMuscles,
                                                instructions: instructions,
                                                customby: nil)
        addCreateExerciseDelegate?.didAddExercise(newExercies!)
        navigationController?.popViewController(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let pickedImage = info[.editedImage] as? UIImage {
            gifUrlImageView.image = pickedImage
            if let imageUrl = saveImageToDocumentsDirectory(image: pickedImage) {
                gifUrl = imageUrl
            }
        }
    }

    func saveImageToDocumentsDirectory(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    @IBAction func pickImageAction(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Using camera", style: .default, handler: { (action) in
                self.pickImageFrom(.camera)
            }))
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            actionSheet.addAction(UIAlertAction(title: "Using photo library", style: .default, handler: { (action) in
                self.pickImageFrom(.photoLibrary)
            }))
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }

    func pickImageFrom(_ sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }

    func displayMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
