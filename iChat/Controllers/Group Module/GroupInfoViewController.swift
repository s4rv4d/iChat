//
//  GroupInfoViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 1/1/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class GroupInfoViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var groupIconView: UIImageView!
    @IBOutlet weak var groupNameTextfield: UITextField!
    @IBOutlet weak var groupIconEdit: UIButton!
    @IBOutlet var groupIconRecog: UITapGestureRecognizer!
    @IBOutlet weak var saveButton: UIButton!
    
    //MARK: - Variables
    var didChange:Bool = false
    var group:NSDictionary!
    var groupIcon:UIImage?
    let imgPickerController = ImagePickerController()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //group icon stuff
        groupIconEdit.isHidden = true
        groupIconView.isUserInteractionEnabled = true
        groupIconView.addGestureRecognizer(groupIconRecog)
        
        //ui
        SetupUI()
        
        //nav bar stuff
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite Users", style: .plain, target: self, action: #selector(self.InviteUsers))]
        
    }
    
    //MARK: - IBActions
    @IBAction func CameraIconTapped(_ sender: UITapGestureRecognizer) {
        ShowIconOption()
    }
    
    @IBAction func EditButtonTapped(_ sender: UIButton) {
        ShowIconOption()
    }
    
    @IBAction func SaveButtonTapped(_ sender: UIButton) {
        var withValues:[String:Any]!
        
        if groupNameTextfield.text != ""{
            withValues = [kNAME:groupNameTextfield.text]
            print("passing through the if condition")
        }else{
            ProgressHUD.showError("Name should'nt be empty")
            return
        }
        
        let avatarData = groupIconView.image?.jpegData(compressionQuality: 0.7)
        let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        withValues = [kNAME:groupNameTextfield.text!,kAVATAR:avatarString!]
        
        Group.UpdateGroup(groupID: group[kGROUPID] as! String, withValues: withValues)
        //for updating recents
        withValues = [kWITHUSERFULLNAME:groupNameTextfield.text!,kAVATAR:avatarString!]
        UpdateExistingRecentWithNewValues(chatroomID: group[kGROUPID] as! String, members: group[kMEMBERS] as! [String], withValues: withValues)
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    //MARK: - Functions
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    
    @objc func InviteUsers(){
        let invVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inv") as! InviteUserTableViewController
        invVC.group = group
        self.navigationController?.pushViewController(invVC, animated: true)
    }
    
    func SetupUI(){
        self.title = "Group"
        groupNameTextfield.text = group[kNAME] as? String
        imageFromData(pictureData: (group[kAVATAR] as? String)!) { (image) in
            if image != nil{
                groupIconView.image = image!.circleMasked
            }
        }
    }
    func ShowIconOption(){
        let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
        let takePhoto = UIAlertAction(title: "Take/Choose Photo", style: .default) { (action) in
            print("camera")
            self.imgPickerController.delegate = self
            self.imgPickerController.imageLimit = 1
            
            //dismiss keyboard
            self.dismissKeyboard()
            self.present(self.imgPickerController, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        if groupIcon != nil{
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (action) in
                self.groupIcon = nil
                self.groupIconView.image = UIImage(named: "cameraIcon")
                self.groupIconEdit.isHidden = true
            }
            optionMenu.addAction(resetAction)
        }
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(cancelAction)
        
        //to check for iPads
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverPresebtationController = optionMenu.popoverPresentationController{
                currentPopoverPresebtationController.sourceView = groupIconEdit
                currentPopoverPresebtationController.sourceRect = groupIconEdit.bounds
                currentPopoverPresebtationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
        }
        
    }

    
    
}

//MARK: - Extensions
extension GroupInfoViewController: ImagePickerDelegate{
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        //do nothing here, just dismiss
        print("hererere")
        //camera class instance
        let camera = Camera(delegate_: self)
        camera.PresentPhotoLibrary(target: self.imgPickerController, canEdit: true)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0{
            self.groupIconEdit.isHidden = false
            self.groupIcon = images.first!
            self.groupIconView.image = self.groupIcon!.circleMasked
        }else{
            self.groupIconEdit.isHidden = true
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        //do nothing here, just dismiss
        self.dismiss(animated: true, completion: nil)
    }
}

extension GroupInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        self.groupIcon = picture
        self.groupIconView.image = self.groupIcon!.circleMasked
        //        picker.dismiss(animated: true, completion: nil)
        picker.dismiss(animated: true) {
            self.imgPickerController.dismiss(animated: true, completion: nil)
        }
    }
}
