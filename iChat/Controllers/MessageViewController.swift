//
//  MessageViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/22/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit
import FirebaseFirestore


//////////IMPORTANT////////////
//SEARCH FOR toggleSendButtonEnabled
//AND MADE CHANGES SET CONTENT TEXT TO TRUE TO ALWAYS ENBLE THE SEND BUTTON
///////////////////////////////

class MessageViewController:  JSQMessagesViewController{
    
    //MARK: - Variables
    
    //JSQ stuff
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //custom header
    let leftBarButton:UIView = {
       let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    let avatarButton:UIButton = {
       let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    let titleLabel:UILabel = {
       let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        return title
    }()
    let subTitleLabel:UILabel = {
       let subTitleLabel = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subTitleLabel.textAlignment = .left
        subTitleLabel.font = UIFont(name: subTitleLabel.font.fontName, size: 14)
        return subTitleLabel
    }()
    
    //chat room stuff
    var chatRoomId:String!
    var memberids:[String]!
    var memberToPush:[String]!
    var isGroup:Bool?
    var group:NSDictionary?
    var withUser:[FUser] = []
    
    //nav var stuff
    var titleName:String!
    
    //proper messages types
    let properMessageTypes = [kAUDIO,kVIDEO,kTEXT,kLOCATION,kPICTURE]
    
    //message constraints
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var loadOld = false
    var loadedMessagesCount = 0
    
    //to hold message
    var messages:[JSQMessage] = []
    var objectMessage:[NSDictionary] = []
    var loadedMessages:[NSDictionary] = []
    var allPictureMessages:[String] = []
    var initialLoadComplete = false
    
    //listeners
    var newChatListener:ListenerRegistration?
    var typingListener:ListenerRegistration?
    var updateListener:ListenerRegistration?
    
    
    //fix iPhoneX UI
    override func viewDidLayoutSubviews() {
        //to fix the bottom,calling the fixing method
        perform(Selector(("jsq_updateCollectionViewInsets")))
    }
     //finishing UI
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //senderid and sender display name comes from jsq pod
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        //nav fixes
        navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.BackAction))]
        
        //default avatar size next to message bubble
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        //custom header
        SetCustomTitle()
        
        LoadMessages()
        //fix iPhoneX UI
        let constraint = perform(Selector(("toolbarBottomLayoutGuide")))?.takeUnretainedValue() as! NSLayoutConstraint
        constraint.priority = UILayoutPriority(rawValue: 1000)
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        //finishing UI
        
        //custom send button
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
    }
    
    //MARK: - JSQ Datasource functions
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        //time stamp after every three messages
        if indexPath.item % 3 == 0{
            let message = messages[indexPath.row]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for:message.date)
        }
            return nil
    }
    
   override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0{
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        //last message read status
        let message = objectMessage[indexPath.row]
        let status:NSAttributedString!
        let attrFormatColor = [NSAttributedStringKey.foregroundColor:UIColor.darkGray]
        
        switch message[kSTATUS] as! String {
        case kDELIVERED:
            status = NSAttributedString(string: kDELIVERED)
        case kREAD:
            let statusText = "Read \(ReadTimeFormat(date: message[kREADDATE] as! String))"
            status = NSAttributedString(string: statusText, attributes: attrFormatColor)
        default:
            status = NSAttributedString(string: "✔️")
        }
        
        if indexPath.row == messages.count - 1{
            return status
        }else{
            return NSAttributedString(string:"")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }else{
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            cell.textView.textColor = .white
        }else{
            cell.textView.textColor = .black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        if data.senderId == FUser.currentId(){
            return outgoingBubble
        }else{
            return incomingBubble
        }
    }
    
    //MARK: - JSQ Delegate functions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory button pressed")
        
        //camera class instance
        let camera = Camera(delegate_: self)
        
        //show option menu
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            print("camera")
        }
        let showPhotoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            print("photo library")
        }
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video library")
        }
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share location")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("cancel")
        }
        //images for accessory
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        showPhotoLibrary.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(showPhotoLibrary)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        //to check for iPads
        if (UI_USER_INTERFACE_IDIOM() == .pad){
            if let currentPopoverPresebtationController = optionMenu.popoverPresentationController{
                currentPopoverPresebtationController.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverPresebtationController.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverPresebtationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        }else{
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("send button pressed")
        
        //to check for text
        if text != ""{
            //for text message to be sent nothing else
            self.SendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            //after send button is pressed
            UpdateSendButton(isSend: false)
        }else{
            print("audio message")
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("load more")
        //load morew messages
        LoadMoreMessages(max: maxMessageNumber, min: minMessageNumber)
        self.collectionView.reloadData()
    }
    
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != ""{
            UpdateSendButton(isSend: true)
        }else{
            UpdateSendButton(isSend: false)
        }
    }
    
    @objc func BackAction(){
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - Functions
    //load more messages
    func LoadMoreMessages(max:Int,min:Int){
        //to update max and min
        if loadOld{
            maxMessageNumber = min - 1
            minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        }
        
        if minMessageNumber < 0 {
           minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed(){
            let msgDict = loadedMessages[i]
            //insert new message
            InsertNewMessage(msgD: msgDict)
            loadedMessagesCount += 1
        }
        
        loadOld = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    func InsertNewMessage(msgD:NSDictionary){
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
        let message = incomingMessage.CreateMessage(messageDict: msgD, chatroomId: chatRoomId)
        objectMessage.insert(msgD, at: 0)
        messages.insert(message!, at: 0)
    }
    
    //Custom send button
    func UpdateSendButton(isSend:Bool){
        if isSend{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        }else{
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        }
    }
    
    //send messages
    func SendMessage(text:String?, date:Date, picture: UIImage?, location:String?, video:NSURL?, audio:String?){
        //create an instance of outgoing message
        var outgoingMessage:OutgoingMessages?
        let currentUser = FUser.currentUser()!
        
        //text message
        if let text = text{
            outgoingMessage = OutgoingMessages(message: text, senderID: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        //sending message sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        outgoingMessage!.SendMessage(chatRoomId: chatRoomId, messageDict: outgoingMessage!.messageDictionary, memberids: memberids, membersToPush: memberToPush)
    }
    
    //loading messages
    func LoadMessages(){
        
        //get last 11 messages
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
            //get 11 messages
            guard let snapshot = snapshot else{
                //initial loading is done
                self.initialLoadComplete = true
                //listening for new chat
                return
            }
            //sorting messages
            let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
            //to remove corrupted messages
            self.loadedMessages = self.RemoveCorruptMessages(allMessages: sorted)
            //insert after converting to JSQMessages
            self.InsertMessages()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComplete = true
            
            print("we have \(self.messages.count) loaded")
            //get picture messages
            //get old messages in background
            self.GetOldMessagesInBackground()
            //start listening for new chats
            self.ListenForNewChat()
            
        }
    }
    
    func ListenForNewChat(){
        var lastMessageDate = "0"
        
        if loadedMessages.count > 0{
            lastMessageDate = loadedMessages.last![kDATE] as! String
        }
        
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else{return}
            
            if !snapshot.isEmpty{
                for diff in snapshot.documentChanges{
                    if diff.type == .added{
                        let item = diff.document.data() as NSDictionary
                        if let type = item[kTYPE]{
                            if self.properMessageTypes.contains(type as! String){
                                if type as! String == kPICTURE{
                                    //for pictures
                                    //add to pictures
                                }
                                
                                if self.InsertInitialLoadedMessages(md: item){
                                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                }
                                
                                self.finishReceivingMessage()
                            }
                        }
                    }
                }
            }
        })
        
    }
    
    func GetOldMessagesInBackground(){
        //getting messages in background
        if loadedMessages.count > 10{
            let firstMessageDate = loadedMessages.first![kDATE] as! String
            //to get older messages
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                guard let snapshot = snapshot else{return}
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                //to bring old messages before the current messages
                self.loadedMessages = self.RemoveCorruptMessages(allMessages: sorted) + self.loadedMessages
                
                //get messages
                
                //to update max and min after getting old messages
                self.maxMessageNumber = self.loadedMessages.count - self.loadedMessagesCount - 1
                self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
            }
        }
    }
    
    func RemoveCorruptMessages(allMessages:[NSDictionary]) -> [NSDictionary]{
        //to make it mutable transfer to temp variables
        var tempMessages = allMessages
        for message in tempMessages{
            if message[kTYPE] != nil{
                if !self.properMessageTypes.contains(message[kTYPE] as! String){
                    //remove the message from temp dict
                    tempMessages.remove(at: tempMessages.index(of:message)!)
                }
            }else{
                tempMessages.remove(at: tempMessages.index(of:message)!)
            }
        }
        return tempMessages
    }
    
    //MARK: - Update UI
    func SetCustomTitle(){
        leftBarButton.addSubview(avatarButton)
        leftBarButton.addSubview(titleLabel)
        leftBarButton.addSubview(subTitleLabel)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.InfoButtonPressed))
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButton)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        if isGroup!{
            avatarButton.addTarget(self, action: #selector(self.ShowGroup), for: .touchUpInside)
        }else{
            avatarButton.addTarget(self, action: #selector(self.ShowUserProfile), for: .touchUpInside)
        }
        
        getUsersFromFirestore(withIds: memberids) { (withUsers) in
            self.withUser = withUsers
            //get avatars
            if !self.isGroup!{
                //update user info
                self.SetupUIForSingleChat()
            }
        }
    }
    
    func SetupUIForSingleChat(){
        let withUsr = withUser.first!
        imageFromData(pictureData: withUsr.avatar) { (img) in
            if img != nil{
                avatarButton.setImage(img!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUsr.fullname
        if withUsr.isOnline{
            subTitleLabel.text = "Online"
        }else{
            subTitleLabel.text = "Offline"
        }
        
        avatarButton.addTarget(self, action: #selector(self.ShowUserProfile), for: .touchUpInside)
    }
    
    @objc func InfoButtonPressed(){
        print("info button tapped to show info")
    }
    
    @objc func ShowGroup(){
        print("show group info")
    }
    
    @objc func ShowUserProfile(){
        print("show user profile info")
        let profileView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        profileView.user = withUser.first!
        self.navigationController?.pushViewController(profileView, animated: true)
    }
    
    //MARK: - Insert Messages
    func InsertMessages(){
        maxMessageNumber = loadedMessages.count - loadedMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0{
            minMessageNumber = 0
        }
        
        //for debugging
        print("max: \(maxMessageNumber)")
        print("min: \(minMessageNumber)")
        
        for i in minMessageNumber ..< maxMessageNumber{
           let messageDictionary = loadedMessages[i]
            
            //insert message
            InsertInitialLoadedMessages(md: messageDictionary)
            loadedMessagesCount += 1
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessages.count)
    }
    
    //to load messages
    func InsertInitialLoadedMessages(md:NSDictionary) -> Bool{
        
        let incomingMsg = IncomingMessage(collectionView_: self.collectionView!)
        
        //check if incoming
        if(md[kSENDERID] as! String) != FUser.currentId(){
            //update message status
        }
        
        let message = incomingMsg.CreateMessage(messageDict: md, chatroomId: chatRoomId)
        
        if message != nil{
            objectMessage.append(md)
            messages.append(message!)
        }
        
        print("messages array \(messages)")
        return IsIncoming(messD:md)
    }
    
    //to check if its an incoming or outgoing message
    func IsIncoming(messD:NSDictionary) -> Bool{
        if FUser.currentId() == messD[kSENDERID] as! String{
            return false
        }else{
            return true
        }
    }
    
    //for time of READ message
    func ReadTimeFormat(date:String) -> String{
        let date = dateFormatter().date(from: date)
        let currentDateformat = dateFormatter()
        currentDateformat.dateFormat = "HH:mm"
        return currentDateformat.string(from: date!)
    }
}

extension JSQMessagesInputToolbar {
    //to fix ui on iPhone X
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = window else { return }
        if #available(iOS 11.0, *) {
            let anchor = window.safeAreaLayoutGuide.bottomAnchor
            bottomAnchor.constraintLessThanOrEqualToSystemSpacingBelow(anchor, multiplier: 1.0).isActive = true
        }
    }
}


extension MessageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //just conforming nothing else, to use functions in Camera class
}
