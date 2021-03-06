//
//  WelcomeViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 7/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

class WelcomeViewController: UIViewController {

    //MARK:IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    //MARK:IBActions
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        dismisskeyboard()
        if emailTextField.text != "" && passwordTextField.text != ""{
            loginUser()
        }else{
            ProgressHUD.showError("Email and Password need to be entered!")
        }
    }
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        dismisskeyboard()
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != ""{
            if passwordTextField.text == repeatPasswordTextField.text{
                registerUser()
            }else{
                ProgressHUD.showError("Passwords dont match!")
            }
        }else{
            ProgressHUD.showError("Email, Password and repeat password need to be entered!")
        }
    }
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        dismisskeyboard()
    }
    
    @IBAction func RegPhone(_ sender: UIButton) {
        //dismisss progress hud
        ProgressHUD.dismiss()
        //clean textfields
        clearKeyboard()
        dismisskeyboard()

        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "phone") as! PhoneNumberViewController
        
        //presenting it
        self.present(mainView, animated: true, completion: nil)
    }
    
    
    //MARK:Helper Functions
    func dismisskeyboard(){
        self.view.endEditing(false)
    }
    
    func clearKeyboard(){
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
    
    func loginUser(){
        print("Logging in")
        ProgressHUD.show("logging...")
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) { (error) in
            if error != nil{
                ProgressHUD.showError(error!.localizedDescription)
                return
            }
            print("here 0")
            //present app
            self.GotoApp()
        }
    }
    
    func registerUser(){
        print("Registering user")
        dismisskeyboard()
        performSegue(withIdentifier: "goToProfileSetup", sender: self)
        clearKeyboard()
    }

    func GotoApp(){
        //dismisss progress hud
        ProgressHUD.dismiss()
        //clean textfields
        clearKeyboard()
        dismisskeyboard()
        
        //posting a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:FUser.currentId()])
        
        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        //presenting it
        self.present(mainView, animated: true, completion: nil)
    }
    
    //MARK:Prepare segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProfileSetup"{
            if let dest = segue.destination as? FinishRegistrationViewController{
                dest.email = emailTextField.text!
                dest.password = passwordTextField.text!
            }
        }
    }
}
