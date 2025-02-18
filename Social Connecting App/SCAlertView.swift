//
//  SCAlertView.swift
//  Social Connecting App
//
//  Created by Akash Dharamshi on 6/15/17.
//  Copyright © 2017 Akash Dharamshi. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import Firebase
import FirebaseAuth
import FirebaseDatabase

var networkSetting = NetworkSettings()
var Brain = SocialInfoBrain()
var apiCalls = APIcalls()
var userProfView = UserProfileViewController()
var account = String()
var textfield = UITextField()
var nameTextField = UITextField()
var phoneTextField = UITextField()
var addressTextField = UITextField()
var emailTextField = UITextField()
var birthdayTextField = UIDatePicker()
var currentAccountName = String()

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


// Pop Up Styles
public enum SCLAlertViewStyle {
    case success, error ,notice ,warning ,info, edit, wait
    case socialPage(String)
    
    
}

// Action Types
public enum SCLActionType {
    case none, selector, closure
}

// Button sub-class
open class SCLButton: UIButton {
    var actionType = SCLActionType.none
    var target:AnyObject!
    var selector:Selector!
    var action:(()->Void)!
    
    
    public init() {
        super.init(frame: CGRect.zero)
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override public init(frame:CGRect) {
        super.init(frame:frame)
    }
}

// Allow alerts to be closed/renamed in a chainable manner
// Example: SCLAlertView().showSuccess(self, title: "Test", subTitle: "Value").close()
open class SCLAlertViewResponder {
    let alertview: SCLAlertView
    
    // Initialisation and Title/Subtitle/Close functions
    public init(alertview: SCLAlertView) {
        self.alertview = alertview
    }
    
    open func setTitle(_ title: String) {
        self.alertview.labelTitle.text = title
    }
    
    open func setSubTitle(_ subTitle: String) {
        self.alertview.viewText.text = subTitle
    }
    
    open func close() {
        self.alertview.hideView()
    }
}

let kCircleHeightBackground: CGFloat = 62.0

// ------------------------------------
// Create and initialize SCALert with members
//
// ------------------------------------

// The Main Class
open class SCLAlertView: UIViewController, GIDSignInUIDelegate {
    let kDefaultShadowOpacity: CGFloat = 0.7
    let kCircleTopPosition: CGFloat = -12.0
    let kCircleBackgroundTopPosition: CGFloat = -15.0
    let kCircleHeight: CGFloat = 56.0
    let kCircleIconHeight: CGFloat = 20.0
    let kTitleTop:CGFloat = 30.0
    let kTitleHeight:CGFloat = 40.0
    let kWindowWidth: CGFloat = 240.0
    var kWindowHeight: CGFloat = 178.0
    var kTextHeight: CGFloat = 90.0
    let kTextFieldHeight: CGFloat = 45.0
    let kButtonHeight: CGFloat = 45.0
    
    // Font
    let kDefaultFont = "AppleSDGothicNeo-Regular"
    let kButtonFont = "AppleSDGothicNeo-SemiBold"
    
    // UI Colour
    var viewColor = UIColor()
    var pressBrightnessFactor = 0.85
    
    // UI Options
    open var showCloseButton = true
    open var showTextField = true
    
    // Members declaration
    var baseView = UIView()
    var labelTitle = UILabel()
    var viewText = UITextView()
    var contentView = UIView()
    var circleBG = UIView(frame:CGRect(x:0, y:0, width:kCircleHeightBackground, height:kCircleHeightBackground))
    var circleView = UIView()
    var circleIconView = UIView()
    var durationTimer: Timer!
    fileprivate var inputs = [UITextField]()
    fileprivate var buttons = [SCLButton]()
    fileprivate var selfReference: SCLAlertView?
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    required public init() {
        super.init(nibName:nil, bundle:nil)
        // Set up main view
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:kDefaultShadowOpacity)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        // Content View
        contentView.backgroundColor = UIColor(white:1, alpha:1)
        contentView.layer.cornerRadius = 5
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.addSubview(labelTitle)
        contentView.addSubview(viewText)
        
        
        // Circle View
        circleBG.backgroundColor = UIColor.white
        circleBG.layer.cornerRadius = circleBG.frame.size.height / 2
        baseView.addSubview(circleBG)
        circleBG.addSubview(circleView)
        let x = (kCircleHeightBackground - kCircleHeight) / 2
        circleView.frame = CGRect(x:x, y:x, width:kCircleHeight, height:kCircleHeight)
        circleView.layer.cornerRadius = circleView.frame.size.height / 2
        // Title
        labelTitle.numberOfLines = 1
        labelTitle.textAlignment = .center
        labelTitle.font = UIFont(name: kDefaultFont, size:20)
        labelTitle.frame = CGRect(x:12, y:kTitleTop, width: kWindowWidth - 24, height:kTitleHeight)
        // View text
        viewText.isEditable = false
        viewText.textAlignment = .center
        viewText.textContainerInset = UIEdgeInsets.zero
        viewText.textContainer.lineFragmentPadding = 0;
        viewText.font = UIFont(name: kDefaultFont, size:14)
        // Colours
        contentView.backgroundColor = UIColorFromRGB(UIColor.white)
        labelTitle.textColor = UIColorFromRGB(UIColor.darkGray)
        viewText.textColor = UIColorFromRGB(UIColor.darkGray)
        contentView.layer.borderColor = UIColorFromRGB(UIColor.lightText).cgColor
        //Gesture Recognizer for tapping outside the textinput
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SCLAlertView.dismissKeyboard))
        tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
        
        
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var sz = UIScreen.main.bounds.size
        let sver = UIDevice.current.systemVersion as NSString
        let ver = sver.floatValue
        if ver < 8.0 {
            // iOS versions before 7.0 did not switch the width and height on device roration
            if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
                let ssz = sz
                sz = CGSize(width:ssz.height, height:ssz.width)
            }
        }
        // Set background frame
        view.frame.size = sz
        
        // computing the right size to use for the textView
        let maxHeight = sz.height - 100 // max overall height
        var consumedHeight = CGFloat(0)
        consumedHeight += kTitleTop + kTitleHeight
        consumedHeight += 14
        consumedHeight += kButtonHeight * CGFloat(buttons.count)
        consumedHeight += kTextFieldHeight * CGFloat(inputs.count)
        let maxViewTextHeight = maxHeight - consumedHeight
        let viewTextWidth = kWindowWidth - 24
        let suggestedViewTextSize = viewText.sizeThatFits(CGSize(width: viewTextWidth, height: CGFloat.greatestFiniteMagnitude))
        let viewTextHeight = min(suggestedViewTextSize.height, maxViewTextHeight)
        
        // scroll management
        if (suggestedViewTextSize.height > maxViewTextHeight) {
            viewText.isScrollEnabled = true
        } else {
            viewText.isScrollEnabled = false
        }
        
        let windowHeight = consumedHeight + viewTextHeight
        // Set frames
        var x = (sz.width - kWindowWidth) / 2
        var y = (sz.height - windowHeight - (kCircleHeight / 8)) / 2
        contentView.frame = CGRect(x:x, y:y, width:kWindowWidth, height:windowHeight)
        y -= kCircleHeightBackground * 0.6
        x = (sz.width - kCircleHeightBackground) / 2
        circleBG.frame = CGRect(x:x, y:y+6, width:kCircleHeightBackground, height:kCircleHeightBackground)
        // Subtitle
        y = kTitleTop + kTitleHeight
        viewText.frame = CGRect(x:12, y:y, width: kWindowWidth - 24, height:kTextHeight)
        viewText.frame = CGRect(x:12, y:y, width: viewTextWidth, height:viewTextHeight)
        // Text fields
        y += viewTextHeight + 14.0
        for txt in inputs {
            txt.frame = CGRect(x:12, y:y, width:kWindowWidth - 24, height:30)
            txt.layer.cornerRadius = 3
            y += kTextFieldHeight
        }
        // Buttons
        for btn in buttons {
            btn.frame = CGRect(x:12, y:y, width:kWindowWidth - 24, height:35)
            btn.layer.cornerRadius = 3
            y += kButtonHeight
        }
    }
    
    
    override open func touchesEnded(_ touches:Set<UITouch>, with event:UIEvent?) {
        if event?.touches(for: view)?.count > 0 {
            view.endEditing(true)
        }
    }
    
    
    // ------------------------------------
    // Add buttons, textfield add and logic
    // ------------------------------------
    
    open func addTextField(_ title:String?=nil)->UITextField {
        // Update view height
        kWindowHeight += kTextFieldHeight
        // Add text field
        let txt = UITextField()
        txt.borderStyle = UITextBorderStyle.roundedRect
        txt.font = UIFont(name:kDefaultFont, size: 14)
        txt.autocapitalizationType = UITextAutocapitalizationType.sentences
        txt.clearButtonMode = UITextFieldViewMode.whileEditing
        txt.returnKeyType = .done
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        txt.autocorrectionType = .no
        
        if title != nil {
            txt.placeholder = title!
        }
        
        if txt.text != ""{
            txt.placeholder = ""
        }
        
        txt.contentVerticalAlignment = .center
        txt.contentHorizontalAlignment = .center
        
        contentView.addSubview(txt)
        inputs.append(txt)
        return txt
    }
    
    open func addDatePicker(_ title:String?=nil)-> UIDatePicker {
        // Update view height
        kWindowHeight += kTextFieldHeight
        // Add text field
        let txt = UIDatePicker()
        txt.datePickerMode = UIDatePickerMode.date
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        
        
        txt.contentVerticalAlignment = .center
        txt.contentHorizontalAlignment = .center
        
        contentView.addSubview(txt)
        //inputs.append(txt)
        return txt
    }
    
    
    
    open func addButton(_ title:String, action:@escaping ()->Void)->SCLButton {
        let btn = addButton(title)
        btn.actionType = SCLActionType.closure
        btn.action = action
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        return btn
    }
    
    open func addButton(_ title:String, target:AnyObject, selector:Selector, accountName:String)-> AnyObject {
        let btn = addButton(title)
        btn.actionType = SCLActionType.selector
        btn.target = target
        btn.selector = selector
        
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        
        
        switch accountName {
            case "Facebook" :
                btn.backgroundColor = hexStringToUIColor(hex: "#3b5998")
            case "Pinterest" :
                btn.backgroundColor = hexStringToUIColor(hex: "#C92228")
            case "LinkedIn" :
                btn.backgroundColor = hexStringToUIColor(hex: "#0077B5")
            case "Google Plus" :
                btn.backgroundColor = hexStringToUIColor(hex: "#D84B37")
            case "YouTube" :
                btn.backgroundColor = hexStringToUIColor(hex: "#CC181E")
            case "Spotify" :
                btn.backgroundColor = hexStringToUIColor(hex: "#1db954")
            case "SoundCloud" :
                btn.backgroundColor = hexStringToUIColor(hex: "#ee6f00")
            case "Yelp" :
                btn.backgroundColor = hexStringToUIColor(hex: "#d32323")
            case "close":
                btn.backgroundColor = hexStringToUIColor(hex: "#9f9f9f")
            default :
                btn.backgroundColor = hexStringToUIColor(hex: "#9f9f9f")
        }
        
        return btn
    }
    
    func createGIDSignInButton() -> GIDSignInButton{
        return GIDSignInButton()
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    fileprivate func addButton(_ title:String)->SCLButton {
        // Update view height
        kWindowHeight += kButtonHeight
        var btn = SCLButton()
        
        btn.layer.masksToBounds = true
        btn.setTitle(title, for: UIControlState())
        btn.titleLabel?.font = UIFont(name:kButtonFont, size: 14)
        contentView.addSubview(btn)
        buttons.append(btn)
        return btn
    }
    
    func buttonTapped(_ btn:SCLButton) {
        if btn.actionType == SCLActionType.closure {
            btn.action()
        } else if btn.actionType == SCLActionType.selector {
            let ctrl = UIControl()
            ctrl.sendAction(btn.selector, to:btn.target, for:nil)
            return
        } else {
            print("Unknow action type for button")
        }
        hideView()
    }
    
    
    func buttonTapDown(_ btn:SCLButton) {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0
        btn.backgroundColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        //brightness = brightness * CGFloat(pressBrightness)
        btn.backgroundColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    func buttonRelease(_ btn:SCLButton) {
        //btn.backgroundColor = viewColor
    }
    
    //Dismiss keyboard when tapped outside textfield
    func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    
    // ------------------------------------
    // Different SCALert Types
    // ------------------------------------
    
    
    // showSuccess(view, title, subTitle)
    open func showSuccess(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 34/255, green: 181/255, blue: 115/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .success, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showSocial(view, title, subTitle)
    open func showSocialPage(_ title: String, subTitle: String, UserAPI: Bool, Account: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 34/255, green: 181/255, blue: 115/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        
        if(UserAPI == true){
            
            //Sends to API login specific pop up
            return showSocialButtonTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .socialPage(Account), colorStyle: colorStyle, colorTextButton: colorTextButton)
  
        }else{
            
            if(title == "Add Card"){
                return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .success, colorStyle: colorStyle, colorTextButton: colorTextButton)
            }
            
            //Sends to username grab pop up
            return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .socialPage(Account), colorStyle: colorStyle, colorTextButton: colorTextButton)
        }
        
        
    }
    
    // showError(view, title, subTitle)
    open func showError(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 193/255, green: 39/255, blue: 45/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitleForClose(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .error, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showNotice(view, title, subTitle)
    open func showNotice(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 114/255, green: 115/255, blue: 117/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .notice, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showWarning(view, title, subTitle)
    open func showWarning(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 193/255, green: 39/255, blue: 45/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .warning, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showInfo(view, title, subTitle)
    open func showInfo(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 40/255, green: 102/255, blue: 191/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .info, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showWait(view, title, subTitle)
    open func showWait(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor = UIColor(red: 214/255, green: 45/255, blue: 165/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .wait, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    open func showEdit(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle:UIColor = UIColor(red: 164/255, green: 41/255, blue: 255/255, alpha: 1.0), colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .edit, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    // showTitle(view, title, subTitle, style)
    open func showTitle(_ title: String, subTitle: String, style: SCLAlertViewStyle, closeButtonTitle:String?=nil, duration:TimeInterval=0.0, colorStyle: UIColor?, colorTextButton: UIColor = UIColor.white) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration:duration, completeText:closeButtonTitle, style: style, colorStyle: colorStyle, colorTextButton: colorTextButton)
    }
    
    open func showSocialButtonTitle(_ title: String, subTitle: String, duration: TimeInterval?, completeText: String?, style: SCLAlertViewStyle, colorStyle: UIColor?, colorTextButton: UIColor) -> SCLAlertViewResponder {
        
            selfReference = self
            view.alpha = 0
            let rv = UIApplication.shared.keyWindow! as UIWindow
            rv.addSubview(view)
            view.frame = rv.bounds
            baseView.frame = rv.bounds
            var accountName = String()

        
            // Alert colour/icon
            viewColor = UIColor()
            var iconImage: UIImage?
            
            // Icon style
            switch style {
            case .success:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfCheckmark
                
            case .socialPage(var Account):
                currentAccountName = Account
                accountName = Account
                Account = Account.lowercased()
                let trimmedAccount = Account.replacingOccurrences(of: " ", with: "")
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = UIImage(named: "\(trimmedAccount)icon")
                
                circleIconView = UIImageView(image: iconImage!)
                circleView.addSubview(circleIconView)
                circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
                circleIconView.clipsToBounds = true
                circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
                
                
            case .error:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfCross
                
            case .notice:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfNotice
                
            case .warning:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfWarning
                
            case .info:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfInfo
                
            case .edit:
                viewColor = UIColorFromRGB(colorStyle!)
                iconImage = SCLAlertViewStyleKit.imageOfEdit
                
            case .wait:
                viewColor = UIColorFromRGB(colorStyle!)

                
            }
            
            // Title
            if !title.isEmpty {
                self.labelTitle.text = title
            }
            
            // Subtitle
            if !subTitle.isEmpty {
                viewText.text = subTitle
                // Adjust text view size, if necessary
                let str = subTitle as NSString
                let attr = [NSFontAttributeName:viewText.font ?? UIFont()]
                let sz = CGSize(width: kWindowWidth - 24, height:90)
                let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
                let ht = ceil(r.size.height)
                if ht < kTextHeight {
                    kWindowHeight -= (kTextHeight - ht)
                    kTextHeight = ht
                }
            }
            
            // Done button
            // Switch with selector for "Log in with" to different API login screens passing accountName
            if showCloseButton {
                let txt = completeText != nil ? completeText! : "Log in With \(accountName)"
                _ = addButton(txt, target:self, selector:#selector(SCLAlertView.apiAfterSubmit), accountName : accountName)
                
                let close = completeText != nil ? completeText! : "Close"
                _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName : "close")
            }
            
            for txt in inputs {
                txt.layer.borderColor = viewColor.cgColor
            }
            for btn in buttons {
                //btn.backgroundColor = viewColor
                btn.setTitleColor(UIColorFromRGB(colorTextButton), for:UIControlState())
            }
            
            // Adding duration
            if duration > 0 {
                durationTimer?.invalidate()
                durationTimer = Timer.scheduledTimer(timeInterval: duration!, target: self, selector: #selector(SCLAlertView.hideViewAfterSubmit), userInfo: nil, repeats: false)
            }
            
            // Animate in the alert view
            self.baseView.frame.origin.y = -400
            UIView.animate(withDuration: 0.2, animations: {
                self.baseView.center.y = rv.center.y + 15
                self.view.alpha = 1
            }, completion: { finished in
                UIView.animate(withDuration: 0.2, animations: {
                    self.baseView.center = rv.center
                })
            })

        
        return SCLAlertViewResponder(alertview: self)
        
    }
    
    // showTitle(view, title, subTitle, duration, style)
    open func showTitle(_ title: String, subTitle: String, duration: TimeInterval?, completeText: String?, style: SCLAlertViewStyle, colorStyle: UIColor?, colorTextButton: UIColor?) -> SCLAlertViewResponder {
        
        selfReference = self
        view.alpha = 0
        let rv = UIApplication.shared.keyWindow! as UIWindow
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds
        
        
        // Alert colour/icon
        viewColor = UIColor()
        var iconImage: UIImage?
        
        // Icon style
        switch style {
        case .success:
            account = "Add Card"
            
            //Image
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = UIImage(named: "addcardicon")
            circleIconView = UIImageView(image: iconImage!)
            circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
            
            circleView.addSubview(circleIconView)
            circleIconView.contentMode = UIViewContentMode.scaleAspectFit
            circleIconView.clipsToBounds = true
            
            circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
            
            //SCAlert Buttons
            if(account == "Add Card"){
                let submit = completeText != nil ? completeText! : "Create Card"
                _ = addButton(submit, target:self, selector:#selector(SCLAlertView.hideViewAfterSubmit), accountName: "")
                
                let close = completeText != nil ? completeText! : "Close"
                _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName : "close")
                
                let textField = addTextField("Name of Card")
                textfield = textField
                
            }
    
        case .socialPage(var Account):
            
            //Sets global variable of which account
            account = Account
            Account = Account.lowercased()
            let trimmedAccount = Account.replacingOccurrences(of: " ", with: "")
            
            //Image
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = UIImage(named: "\(trimmedAccount)icon")
            
            circleIconView = UIImageView(image: iconImage!)
            circleView.addSubview(circleIconView)
            circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
            circleIconView.clipsToBounds = true
            circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
            
            showTextField = true
            
            
            //SCALert Buttons
            let submit = completeText != nil ? completeText! : "Submit"
            _ = addButton(submit, target:self, selector:#selector(SCLAlertView.hideViewAfterSubmit), accountName: "")
                
            let close = completeText != nil ? completeText! : "Close"
            _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName : "close")
            
            if(account == "Contact"){
                nameTextField = addTextField("Name")
                phoneTextField = addTextField("Phone")
                addressTextField = addTextField("Address")
                emailTextField = addTextField("Email")
                //birthdayTextField = addDatePicker()
            }else if(account == "Website"){
                let textField = addTextField("Website URL")
                textfield = textField
            }else if(account == "Spotify"){
                let textField = addTextField("Spotify Link")
                textfield = textField
            }else if(account == "SoundCloud"){
                let textField = addTextField("Soundcloud Link")
                textfield = textField
            }else if(account == "Pinterest"){
                let textField = addTextField("Ex: www.pinterest.com/johndoe")
                textfield = textField
            }else if(account == "Yelp"){
                let textField = addTextField("Ex: www.yelp.com/biz/johndoe")
                textfield = textField
            }else {
                let textField = addTextField("Username")
                
                let leftImageView = UIImageView()
                leftImageView.image = UIImage(named: "@icon")
                let leftView = UIView()
                leftView.addSubview(leftImageView)
                leftView.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
                leftImageView.frame = CGRect(x: 10, y: 10, width: 20, height: 20)
                textField.leftViewMode = .always
                textField.leftView = leftView
                textfield = textField
            }

            
        case .error:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfCross
            
        case .notice:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfNotice
            
        case .warning:
            account = title
            
            //Image
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = UIImage(named: "deletecell")
            circleIconView = UIImageView(image: iconImage!)
            circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
            
            circleView.addSubview(circleIconView)
            circleIconView.contentMode = UIViewContentMode.scaleAspectFit
            circleIconView.clipsToBounds = true
            
            circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
            
            //SCALert Buttons
            if(account == "Delete Cell"){
                let delete = completeText != nil ? completeText! : "Delete"
                _ = addButton(delete, target:self, selector:#selector(SCLAlertView.hideViewAfterSubmit), accountName: "")
                
                let close = completeText != nil ? completeText! : "Close"
                _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName : "close")
                
                textfield.isHidden = true
            }
            
        case .info:
            account = title
            
            //Image
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = UIImage(named: "warningicon")
            circleIconView = UIImageView(image: iconImage!)
            circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
            
            circleView.addSubview(circleIconView)
            circleIconView.contentMode = UIViewContentMode.scaleAspectFit
            circleIconView.clipsToBounds = true
            
            circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
            
            //SCALert Buttons
            if(account == "Login Error" || account == "Error"){
                
                let close = completeText != nil ? completeText! : "Close"
                _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName : "close")
                
                
            }
            
        case .edit:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfEdit
            
        case .wait:
            viewColor = UIColorFromRGB(colorStyle!)
            
        }
        
        // Title
        if !title.isEmpty {
            self.labelTitle.text = title
        }
        
        // Subtitle
        if !subTitle.isEmpty {
            viewText.text = subTitle
            // Adjust text view size, if necessary
            let str = subTitle as NSString
            let attr = [NSFontAttributeName:viewText.font ?? UIFont()]
            let sz = CGSize(width: kWindowWidth - 24, height:90)
            let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
            let ht = ceil(r.size.height)
            if ht < kTextHeight {
                kWindowHeight -= (kTextHeight - ht)
                kTextHeight = ht
            }
        }
        
        
        for txt in inputs {
            txt.layer.borderColor = viewColor.cgColor
            
        }
        
        for btn in buttons {
            btn.backgroundColor = viewColor
            btn.setTitleColor(UIColorFromRGB(colorTextButton!), for:UIControlState())
        }
        
        // Adding duration
        if duration > 0 {
            durationTimer?.invalidate()
            durationTimer = Timer.scheduledTimer(timeInterval: duration!, target: self, selector: #selector(SCLAlertView.hideViewAfterSubmit), userInfo: nil, repeats: false)
        }
        
        // Animate in the alert view
        self.baseView.frame.origin.y = -400
        UIView.animate(withDuration: 0.2, animations: {
            self.baseView.center.y = rv.center.y + 15
            self.view.alpha = 1
        }, completion: { finished in
            UIView.animate(withDuration: 0.2, animations: {
                self.baseView.center = rv.center
            })
        })
        
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
    }
    
    
    open func showTitleForClose(_ title: String, subTitle: String, duration: TimeInterval?, completeText: String?, style: SCLAlertViewStyle, colorStyle: UIColor?, colorTextButton: UIColor?) -> SCLAlertViewResponder {
        
        selfReference = self
        view.alpha = 0
        let rv = UIApplication.shared.keyWindow! as UIWindow
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds
        
        
        // Alert colour/icon
        viewColor = UIColor()
        var iconImage: UIImage?
        
        // Icon style
        switch style {
        case .success:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfCheckmark
            
        case .socialPage(var Account):
            
            account = Account
            
            Account = Account.lowercased()
            let trimmedAccount = Account.replacingOccurrences(of: " ", with: "")
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = UIImage(named: "\(trimmedAccount)icon")
            
            circleIconView = UIImageView(image: iconImage!)
            circleView.addSubview(circleIconView)
            circleIconView.frame = CGRect(x:0, y:0, width:kCircleHeight, height:kCircleHeight)
            circleIconView.clipsToBounds = true
            circleIconView.layer.cornerRadius = circleIconView.frame.size.height / 2
            
            showTextField = true
            
            
        case .error:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfCross
            
        case .notice:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfNotice
            
        case .warning:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfWarning
            
        case .info:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfInfo
            
        case .edit:
            viewColor = UIColorFromRGB(colorStyle!)
            iconImage = SCLAlertViewStyleKit.imageOfEdit
            
        case .wait:
            viewColor = UIColorFromRGB(colorStyle!)

        }
        
        // Title
        if !title.isEmpty {
            self.labelTitle.text = title
        }
        
        // Subtitle
        if !subTitle.isEmpty {
            viewText.text = subTitle
            // Adjust text view size, if necessary
            let str = subTitle as NSString
            let attr = [NSFontAttributeName:viewText.font ?? UIFont()]
            let sz = CGSize(width: kWindowWidth - 24, height:90)
            let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
            let ht = ceil(r.size.height)
            if ht < kTextHeight {
                kWindowHeight -= (kTextHeight - ht)
                kTextHeight = ht
            }
        }
        
        // Done button
        if showCloseButton {
            
            let close = completeText != nil ? completeText! : "Close"
            _ = addButton(close, target:self, selector:#selector(SCLAlertView.hideView), accountName:"close")
        }
        
        
        for txt in inputs {
            txt.layer.borderColor = viewColor.cgColor
            
        }
        
        for btn in buttons {
            btn.backgroundColor = viewColor
            btn.setTitleColor(UIColorFromRGB(colorTextButton!), for:UIControlState())
        }
        
        // Adding duration
        if duration > 0 {
            durationTimer?.invalidate()
            durationTimer = Timer.scheduledTimer(timeInterval: duration!, target: self, selector: #selector(SCLAlertView.hideViewAfterSubmit), userInfo: nil, repeats: false)
        }
        
        // Animate in the alert view
        self.baseView.frame.origin.y = -400
        UIView.animate(withDuration: 0.2, animations: {
            self.baseView.center.y = rv.center.y + 15
            self.view.alpha = 1
        }, completion: { finished in
            UIView.animate(withDuration: 0.2, animations: {
                self.baseView.center = rv.center
            })
        })
        
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
    }
    
    
    
    
    
    // ------------------------------------
    // Submit and Hide Logic
    // ------------------------------------
    
    // Close SCLAlertView after grabbing information
    open func hideViewAfterSubmit() {
        
        //Add Card logic
        if(account == "Add Card"){
        
            if(textfield.text == ""){
                
                let alert = SCLAlertView()
                _ = alert.showInfo("Error", subTitle: "The Name field cannot be blank!")
                
                account == "Add Card"
                
            }else{
                networkSetting.createSubAccount(photoUrl: "test", uniqueUsername: "test", name: textfield.text!)
                hideView()

            }
        
        //Delete Card Logic
        }else if(account == "Delete Cell"){
            
            networkSetting.deleteSubAccount()
            hideView()

        //Save Account
        }else{
            saveUser()
            hideView()
            
        }
        
        
    }
    
    //Calls after submit
    open func apiAfterSubmit() {
        hideView()
        apiCalls.apiRLoginequest(accountname : currentAccountName)
    }
    
    //Hides view
    open func hideView(){
        
        if(account == "Error" || account == "Login Error"){
            account = "Add Card"
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
        }, completion: { finished in

            self.view.removeFromSuperview()
            self.selfReference = nil
        })
    
    }
    
    
    //Saves social info into database
    open func saveUser(){
        
        let text: NSString = textfield.text as! NSString
        var url = String()
        var fallbackUrl = String()
        
        if(account == "Contact"){
            
            networkSetting.saveContactDB(name: nameTextField.text!, phoneNum: phoneTextField.text!, address: addressTextField.text!, email: emailTextField.text!, birthday: "change")
            
        }else{
        
            if (text != ""){
            
                if let socialUserSchema = Brain.AccountInfo[account]{
                
                    switch socialUserSchema {
                        
                        case .etsyUrl:
                            url = "https://www.etsy.com/shop/\(text)"
                            fallbackUrl = url
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        case .snapchatUrl:
                            url = "www.snapchat.com/add/\(text)"
                            fallbackUrl = url
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        case .twitterUrl:
                            url = "twitter://user?screen_name=\(text)"
                            fallbackUrl = "www.twitter.com/\(text)"
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        case .instagramUrl:
                            url = "instagram://user?username=\(text)"
                            fallbackUrl = "www.instagram.com/\(text)"
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        case .venmoUrl:
                            url = "www.venmo.com/\(text)"
                            fallbackUrl = url
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        case .vimeoUrl:
                            url = "https://vimeo.com/\(text)"
                            fallbackUrl = url
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        
                        case .soundcloudUrl, .spotifyUrl, .pinterestUrl, .yelpUrl, .websiteUrl:
                            url = text as String
                            fallbackUrl = url
                            networkSetting.saveSocialAccountstoDB(url: url, fallbackUrl : fallbackUrl, account: account)
                        
                        
                        default: break
                        

                    }
            
                }
            
            }
        
        }
    }
    
    
    // Helper function to convert from RGB to UIColor
    func UIColorFromRGB(_ rgbValue: UIColor) -> UIColor {
        return rgbValue /*(
         
         /*
         red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
         green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
         blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
         alpha: CGFloat(1.0)*/
         )*/
    }
    
    
    
    
}


// ------------------------------------
// Icon drawing
// Code generated by PaintCode
// ------------------------------------

class SCLAlertViewStyleKit : NSObject {
    
    // Cache
    struct Cache {
        static var imageOfCheckmark: UIImage?
        static var checkmarkTargets: [AnyObject]?
        static var imageOfCross: UIImage?
        static var crossTargets: [AnyObject]?
        static var imageOfNotice: UIImage?
        static var noticeTargets: [AnyObject]?
        static var imageOfWarning: UIImage?
        static var warningTargets: [AnyObject]?
        static var imageOfInfo: UIImage?
        static var infoTargets: [AnyObject]?
        static var imageOfEdit: UIImage?
        static var editTargets: [AnyObject]?
    }
    
    // Initialization
    /// swift 1.2 abolish func load
    //    override class func load() {
    //    }
    
    // Drawing Methods
    class func drawCheckmark() {
        // Checkmark Shape Drawing
        let checkmarkShapePath = UIBezierPath()
        checkmarkShapePath.move(to: CGPoint(x: 73.25, y: 14.05))
        checkmarkShapePath.addCurve(to: CGPoint(x: 64.51, y: 13.86), controlPoint1: CGPoint(x: 70.98, y: 11.44), controlPoint2: CGPoint(x: 66.78, y: 11.26))
        checkmarkShapePath.addLine(to: CGPoint(x: 27.46, y: 52))
        checkmarkShapePath.addLine(to: CGPoint(x: 15.75, y: 39.54))
        checkmarkShapePath.addCurve(to: CGPoint(x: 6.84, y: 39.54), controlPoint1: CGPoint(x: 13.48, y: 36.93), controlPoint2: CGPoint(x: 9.28, y: 36.93))
        checkmarkShapePath.addCurve(to: CGPoint(x: 6.84, y: 49.02), controlPoint1: CGPoint(x: 4.39, y: 42.14), controlPoint2: CGPoint(x: 4.39, y: 46.42))
        checkmarkShapePath.addLine(to: CGPoint(x: 22.91, y: 66.14))
        checkmarkShapePath.addCurve(to: CGPoint(x: 27.28, y: 68), controlPoint1: CGPoint(x: 24.14, y: 67.44), controlPoint2: CGPoint(x: 25.71, y: 68))
        checkmarkShapePath.addCurve(to: CGPoint(x: 31.65, y: 66.14), controlPoint1: CGPoint(x: 28.86, y: 68), controlPoint2: CGPoint(x: 30.43, y: 67.26))
        checkmarkShapePath.addLine(to: CGPoint(x: 73.08, y: 23.35))
        checkmarkShapePath.addCurve(to: CGPoint(x: 73.25, y: 14.05), controlPoint1: CGPoint(x: 75.52, y: 20.75), controlPoint2: CGPoint(x: 75.7, y: 16.65))
        checkmarkShapePath.close()
        checkmarkShapePath.miterLimit = 4;
        
        UIColor.white.setFill()
        checkmarkShapePath.fill()
    }
    
    class func drawCross() {
        // Cross Shape Drawing
        let crossShapePath = UIBezierPath()
        crossShapePath.move(to: CGPoint(x: 10, y: 70))
        crossShapePath.addLine(to: CGPoint(x: 70, y: 10))
        crossShapePath.move(to: CGPoint(x: 10, y: 10))
        crossShapePath.addLine(to: CGPoint(x: 70, y: 70))
        crossShapePath.lineCapStyle = CGLineCap.round;
        crossShapePath.lineJoinStyle = CGLineJoin.round;
        UIColor.white.setStroke()
        crossShapePath.lineWidth = 14
        crossShapePath.stroke()
    }
    
    class func drawNotice() {
        // Notice Shape Drawing
        let noticeShapePath = UIBezierPath()
        noticeShapePath.move(to: CGPoint(x: 72, y: 48.54))
        noticeShapePath.addLine(to: CGPoint(x: 72, y: 39.9))
        noticeShapePath.addCurve(to: CGPoint(x: 66.38, y: 34.01), controlPoint1: CGPoint(x: 72, y: 36.76), controlPoint2: CGPoint(x: 69.48, y: 34.01))
        noticeShapePath.addCurve(to: CGPoint(x: 61.53, y: 35.97), controlPoint1: CGPoint(x: 64.82, y: 34.01), controlPoint2: CGPoint(x: 62.69, y: 34.8))
        noticeShapePath.addCurve(to: CGPoint(x: 60.36, y: 35.78), controlPoint1: CGPoint(x: 61.33, y: 35.97), controlPoint2: CGPoint(x: 62.3, y: 35.78))
        noticeShapePath.addLine(to: CGPoint(x: 60.36, y: 33.22))
        noticeShapePath.addCurve(to: CGPoint(x: 54.16, y: 26.16), controlPoint1: CGPoint(x: 60.36, y: 29.3), controlPoint2: CGPoint(x: 57.65, y: 26.16))
        noticeShapePath.addCurve(to: CGPoint(x: 48.73, y: 29.89), controlPoint1: CGPoint(x: 51.64, y: 26.16), controlPoint2: CGPoint(x: 50.67, y: 27.73))
        noticeShapePath.addLine(to: CGPoint(x: 48.73, y: 28.71))
        noticeShapePath.addCurve(to: CGPoint(x: 43.49, y: 21.64), controlPoint1: CGPoint(x: 48.73, y: 24.78), controlPoint2: CGPoint(x: 46.98, y: 21.64))
        noticeShapePath.addCurve(to: CGPoint(x: 39.03, y: 25.37), controlPoint1: CGPoint(x: 40.97, y: 21.64), controlPoint2: CGPoint(x: 39.03, y: 23.01))
        noticeShapePath.addLine(to: CGPoint(x: 39.03, y: 9.07))
        noticeShapePath.addCurve(to: CGPoint(x: 32.24, y: 2), controlPoint1: CGPoint(x: 39.03, y: 5.14), controlPoint2: CGPoint(x: 35.73, y: 2))
        noticeShapePath.addCurve(to: CGPoint(x: 25.45, y: 9.07), controlPoint1: CGPoint(x: 28.56, y: 2), controlPoint2: CGPoint(x: 25.45, y: 5.14))
        noticeShapePath.addLine(to: CGPoint(x: 25.45, y: 41.47))
        noticeShapePath.addCurve(to: CGPoint(x: 24.29, y: 43.44), controlPoint1: CGPoint(x: 25.45, y: 42.45), controlPoint2: CGPoint(x: 24.68, y: 43.04))
        noticeShapePath.addCurve(to: CGPoint(x: 9.55, y: 43.04), controlPoint1: CGPoint(x: 16.73, y: 40.88), controlPoint2: CGPoint(x: 11.88, y: 40.69))
        noticeShapePath.addCurve(to: CGPoint(x: 8, y: 46.58), controlPoint1: CGPoint(x: 8.58, y: 43.83), controlPoint2: CGPoint(x: 8, y: 45.2))
        noticeShapePath.addCurve(to: CGPoint(x: 14.4, y: 55.81), controlPoint1: CGPoint(x: 8.19, y: 50.31), controlPoint2: CGPoint(x: 12.07, y: 53.84))
        noticeShapePath.addLine(to: CGPoint(x: 27.2, y: 69.56))
        noticeShapePath.addCurve(to: CGPoint(x: 42.91, y: 77.8), controlPoint1: CGPoint(x: 30.5, y: 74.47), controlPoint2: CGPoint(x: 35.73, y: 77.21))
        noticeShapePath.addCurve(to: CGPoint(x: 43.88, y: 77.8), controlPoint1: CGPoint(x: 43.3, y: 77.8), controlPoint2: CGPoint(x: 43.68, y: 77.8))
        noticeShapePath.addCurve(to: CGPoint(x: 47.18, y: 78), controlPoint1: CGPoint(x: 45.04, y: 77.8), controlPoint2: CGPoint(x: 46.01, y: 78))
        noticeShapePath.addLine(to: CGPoint(x: 48.34, y: 78))
        noticeShapePath.addLine(to: CGPoint(x: 48.34, y: 78))
        noticeShapePath.addCurve(to: CGPoint(x: 71.61, y: 52.08), controlPoint1: CGPoint(x: 56.48, y: 78), controlPoint2: CGPoint(x: 69.87, y: 75.05))
        noticeShapePath.addCurve(to: CGPoint(x: 72, y: 48.54), controlPoint1: CGPoint(x: 71.81, y: 51.29), controlPoint2: CGPoint(x: 72, y: 49.72))
        noticeShapePath.close()
        noticeShapePath.miterLimit = 4;
        
        UIColor.white.setFill()
        noticeShapePath.fill()
    }
    
    class func drawWarning() {
        // Color Declarations
        let greyColor = UIColor(red: 0.236, green: 0.236, blue: 0.236, alpha: 1.000)
        
        // Warning Group
        // Warning Circle Drawing
        let warningCirclePath = UIBezierPath()
        warningCirclePath.move(to: CGPoint(x: 40.94, y: 63.39))
        warningCirclePath.addCurve(to: CGPoint(x: 36.03, y: 65.55), controlPoint1: CGPoint(x: 39.06, y: 63.39), controlPoint2: CGPoint(x: 37.36, y: 64.18))
        warningCirclePath.addCurve(to: CGPoint(x: 34.14, y: 70.45), controlPoint1: CGPoint(x: 34.9, y: 66.92), controlPoint2: CGPoint(x: 34.14, y: 68.49))
        warningCirclePath.addCurve(to: CGPoint(x: 36.22, y: 75.54), controlPoint1: CGPoint(x: 34.14, y: 72.41), controlPoint2: CGPoint(x: 34.9, y: 74.17))
        warningCirclePath.addCurve(to: CGPoint(x: 40.94, y: 77.5), controlPoint1: CGPoint(x: 37.54, y: 76.91), controlPoint2: CGPoint(x: 39.06, y: 77.5))
        warningCirclePath.addCurve(to: CGPoint(x: 45.86, y: 75.35), controlPoint1: CGPoint(x: 42.83, y: 77.5), controlPoint2: CGPoint(x: 44.53, y: 76.72))
        warningCirclePath.addCurve(to: CGPoint(x: 47.93, y: 70.45), controlPoint1: CGPoint(x: 47.18, y: 74.17), controlPoint2: CGPoint(x: 47.93, y: 72.41))
        warningCirclePath.addCurve(to: CGPoint(x: 45.86, y: 65.35), controlPoint1: CGPoint(x: 47.93, y: 68.49), controlPoint2: CGPoint(x: 47.18, y: 66.72))
        warningCirclePath.addCurve(to: CGPoint(x: 40.94, y: 63.39), controlPoint1: CGPoint(x: 44.53, y: 64.18), controlPoint2: CGPoint(x: 42.83, y: 63.39))
        warningCirclePath.close()
        warningCirclePath.miterLimit = 4;
        
        greyColor.setFill()
        warningCirclePath.fill()
        
        
        // Warning Shape Drawing
        let warningShapePath = UIBezierPath()
        warningShapePath.move(to: CGPoint(x: 46.23, y: 4.26))
        warningShapePath.addCurve(to: CGPoint(x: 40.94, y: 2.5), controlPoint1: CGPoint(x: 44.91, y: 3.09), controlPoint2: CGPoint(x: 43.02, y: 2.5))
        warningShapePath.addCurve(to: CGPoint(x: 34.71, y: 4.26), controlPoint1: CGPoint(x: 38.68, y: 2.5), controlPoint2: CGPoint(x: 36.03, y: 3.09))
        warningShapePath.addCurve(to: CGPoint(x: 31.5, y: 8.77), controlPoint1: CGPoint(x: 33.01, y: 5.44), controlPoint2: CGPoint(x: 31.5, y: 7.01))
        warningShapePath.addLine(to: CGPoint(x: 31.5, y: 19.36))
        warningShapePath.addLine(to: CGPoint(x: 34.71, y: 54.44))
        warningShapePath.addCurve(to: CGPoint(x: 40.38, y: 58.16), controlPoint1: CGPoint(x: 34.9, y: 56.2), controlPoint2: CGPoint(x: 36.41, y: 58.16))
        warningShapePath.addCurve(to: CGPoint(x: 45.67, y: 54.44), controlPoint1: CGPoint(x: 44.34, y: 58.16), controlPoint2: CGPoint(x: 45.67, y: 56.01))
        warningShapePath.addLine(to: CGPoint(x: 48.5, y: 19.36))
        warningShapePath.addLine(to: CGPoint(x: 48.5, y: 8.77))
        warningShapePath.addCurve(to: CGPoint(x: 46.23, y: 4.26), controlPoint1: CGPoint(x: 48.5, y: 7.01), controlPoint2: CGPoint(x: 47.74, y: 5.44))
        warningShapePath.close()
        warningShapePath.miterLimit = 4;
        
        greyColor.setFill()
        warningShapePath.fill()
    }
    
    class func drawInfo() {
        // Color Declarations
        let color0 = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        
        // Info Shape Drawing
        let infoShapePath = UIBezierPath()
        infoShapePath.move(to: CGPoint(x: 45.66, y: 15.96))
        infoShapePath.addCurve(to: CGPoint(x: 45.66, y: 5.22), controlPoint1: CGPoint(x: 48.78, y: 12.99), controlPoint2: CGPoint(x: 48.78, y: 8.19))
        infoShapePath.addCurve(to: CGPoint(x: 34.34, y: 5.22), controlPoint1: CGPoint(x: 42.53, y: 2.26), controlPoint2: CGPoint(x: 37.47, y: 2.26))
        infoShapePath.addCurve(to: CGPoint(x: 34.34, y: 15.96), controlPoint1: CGPoint(x: 31.22, y: 8.19), controlPoint2: CGPoint(x: 31.22, y: 12.99))
        infoShapePath.addCurve(to: CGPoint(x: 45.66, y: 15.96), controlPoint1: CGPoint(x: 37.47, y: 18.92), controlPoint2: CGPoint(x: 42.53, y: 18.92))
        infoShapePath.close()
        infoShapePath.move(to: CGPoint(x: 48, y: 69.41))
        infoShapePath.addCurve(to: CGPoint(x: 40, y: 77), controlPoint1: CGPoint(x: 48, y: 73.58), controlPoint2: CGPoint(x: 44.4, y: 77))
        infoShapePath.addLine(to: CGPoint(x: 40, y: 77))
        infoShapePath.addCurve(to: CGPoint(x: 32, y: 69.41), controlPoint1: CGPoint(x: 35.6, y: 77), controlPoint2: CGPoint(x: 32, y: 73.58))
        infoShapePath.addLine(to: CGPoint(x: 32, y: 35.26))
        infoShapePath.addCurve(to: CGPoint(x: 40, y: 27.67), controlPoint1: CGPoint(x: 32, y: 31.08), controlPoint2: CGPoint(x: 35.6, y: 27.67))
        infoShapePath.addLine(to: CGPoint(x: 40, y: 27.67))
        infoShapePath.addCurve(to: CGPoint(x: 48, y: 35.26), controlPoint1: CGPoint(x: 44.4, y: 27.67), controlPoint2: CGPoint(x: 48, y: 31.08))
        infoShapePath.addLine(to: CGPoint(x: 48, y: 69.41))
        infoShapePath.close()
        color0.setFill()
        infoShapePath.fill()
    }
    
    class func drawEdit() {
        // Color Declarations
        let color = UIColor(red:1.0, green:1.0, blue:1.0, alpha:1.0)
        
        // Edit shape Drawing
        let editPathPath = UIBezierPath()
        editPathPath.move(to: CGPoint(x: 71, y: 2.7))
        editPathPath.addCurve(to: CGPoint(x: 71.9, y: 15.2), controlPoint1: CGPoint(x: 74.7, y: 5.9), controlPoint2: CGPoint(x: 75.1, y: 11.6))
        editPathPath.addLine(to: CGPoint(x: 64.5, y: 23.7))
        editPathPath.addLine(to: CGPoint(x: 49.9, y: 11.1))
        editPathPath.addLine(to: CGPoint(x: 57.3, y: 2.6))
        editPathPath.addCurve(to: CGPoint(x: 69.7, y: 1.7), controlPoint1: CGPoint(x: 60.4, y: -1.1), controlPoint2: CGPoint(x: 66.1, y: -1.5))
        editPathPath.addLine(to: CGPoint(x: 71, y: 2.7))
        editPathPath.addLine(to: CGPoint(x: 71, y: 2.7))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.addLine(to: CGPoint(x: 13.4, y: 53.1))
        editPathPath.addLine(to: CGPoint(x: 15.7, y: 55.1))
        editPathPath.addLine(to: CGPoint(x: 50.1, y: 15.5))
        editPathPath.addLine(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.addLine(to: CGPoint(x: 47.8, y: 13.5))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.addLine(to: CGPoint(x: 23.8, y: 62.2))
        editPathPath.addLine(to: CGPoint(x: 58.2, y: 22.6))
        editPathPath.addLine(to: CGPoint(x: 52, y: 17.1))
        editPathPath.addLine(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.addLine(to: CGPoint(x: 17.7, y: 56.7))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.addLine(to: CGPoint(x: 60.1, y: 24.2))
        editPathPath.addLine(to: CGPoint(x: 62.3, y: 26.1))
        editPathPath.addLine(to: CGPoint(x: 28.1, y: 65.7))
        editPathPath.addLine(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.addLine(to: CGPoint(x: 25.8, y: 63.8))
        editPathPath.close()
        editPathPath.move(to: CGPoint(x: 25.9, y: 68.1))
        editPathPath.addLine(to: CGPoint(x: 4.2, y: 79.5))
        editPathPath.addLine(to: CGPoint(x: 11.3, y: 55.5))
        editPathPath.addLine(to: CGPoint(x: 25.9, y: 68.1))
        editPathPath.close()
        editPathPath.miterLimit = 4;
        editPathPath.usesEvenOddFillRule = true;
        color.setFill()
        editPathPath.fill()
    }
    
    // Generated Images
    class var imageOfCheckmark: UIImage {
        if (Cache.imageOfCheckmark != nil) {
            return Cache.imageOfCheckmark!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawCheckmark()
        Cache.imageOfCheckmark = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCheckmark!
    }
    
    
    class var imageOfCross: UIImage {
        if (Cache.imageOfCross != nil) {
            return Cache.imageOfCross!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawCross()
        Cache.imageOfCross = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfCross!
    }
    
    class var imageOfNotice: UIImage {
        if (Cache.imageOfNotice != nil) {
            return Cache.imageOfNotice!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawNotice()
        Cache.imageOfNotice = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfNotice!
    }
    
    class var imageOfWarning: UIImage {
        if (Cache.imageOfWarning != nil) {
            return Cache.imageOfWarning!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawWarning()
        Cache.imageOfWarning = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfWarning!
    }
    
    class var imageOfInfo: UIImage {
        if (Cache.imageOfInfo != nil) {
            return Cache.imageOfInfo!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawInfo()
        Cache.imageOfInfo = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfInfo!
    }
    
    class var imageOfEdit: UIImage {
        if (Cache.imageOfEdit != nil) {
            return Cache.imageOfEdit!
        }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 80, height: 80), false, 0)
        SCLAlertViewStyleKit.drawEdit()
        Cache.imageOfEdit = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return Cache.imageOfEdit!
    }
}

