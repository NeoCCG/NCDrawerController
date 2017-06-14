//  Created by Neo Chen on 15/6/9.
//  Drawer Controller

import UIKit

class NCDrawerController: UIViewController,UIGestureRecognizerDelegate {
    
    fileprivate let _flexibleAll:UIViewAutoresizing = [.flexibleLeftMargin , .flexibleWidth , .flexibleRightMargin , .flexibleTopMargin , .flexibleHeight , .flexibleBottomMargin]
    fileprivate let _flexibleLeft:UIViewAutoresizing = [.flexibleRightMargin , .flexibleTopMargin , .flexibleHeight , .flexibleBottomMargin]
    
    // drawer menu 出现方向
    enum NCDrawerDirection {
        case left
        case right
        case top
        case bottom
    }
    
    // drawer menu 出现方式
    enum NCDrawerType {
        case cover                  //drawerMenu覆盖在主视图上面
        case push                   //drawerMenu推出主视图
        case background         //drawerMenu在主视图背面
    }
    

    //抽屉参数
    
    /// 是否打开抽屉功能
    var enableMenu:Bool = true
    /// 抽屉视图尺寸
    var drawerSize:CGFloat = 200
    /// 抽屉视图是否显示中
    var isShowingMenu:Bool = false
    /// 抽屉视图方面
    var drawerDirection:NCDrawerDirection = .left
    /// 抽屉视图显示方式
    var drawerType:NCDrawerType = .cover
    /// 主视图随抽屉缩小最大比例
    var transparentMaxScale:CGFloat = 0.1
    
    var drawerMenu:UIView = UIView()
    fileprivate var btnMenuClose:UIButton = UIButton()
    var transparent:UIView = UIView()
    
    var rootViewController:UIViewController? {
        didSet {
            if let o = oldValue {
                o.view.removeFromSuperview()
                o.removeFromParentViewController()
            }
            if let c = rootViewController {
                self.addChildViewController(c)
                self.transparent.addSubview(c.view)
                c.view.frame = self.transparent.bounds
                c.view.autoresizingMask = _flexibleAll
            }
        }
    }
    
    var drawerViewController:UIViewController? {
        didSet {
            if let o = oldValue {
                o.view.removeFromSuperview()
                o.removeFromParentViewController()
            }
            if let c = drawerViewController {
                self.addChildViewController(c)
                self.drawerMenu.addSubview(c.view)
                c.view.frame = self.drawerMenu.bounds
                c.view.autoresizingMask = _flexibleAll
            }
        }
    }
    
    // 优化控制参数
    fileprivate var __maxLength:CGFloat = 0
    fileprivate var __minLength:CGFloat = 0
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(transparent)
        self.view.addSubview(btnMenuClose)
        self.view.addSubview(drawerMenu)
        
        drawerSize = ceil(UIScreen.main.bounds.size.width * 0.75)
        
        transparent.frame = self.view.bounds
        transparent.autoresizingMask = _flexibleAll
        btnMenuClose.frame = self.view.bounds
        btnMenuClose.autoresizingMask = _flexibleAll
        drawerMenu.frame = CGRect(x: self.view.frame.width, y: 0, width: drawerSize, height: self.view.frame.height)
        drawerMenu.autoresizingMask = _flexibleLeft
        
        btnMenuClose.backgroundColor = UIColor(white: 0, alpha: 0.5)
        btnMenuClose.addTarget(self, action:#selector(NCDrawerController.menuSwitchAction(_:)), for: UIControlEvents.touchUpInside)
        btnMenuClose.isHidden = true
        
        let g = UIPanGestureRecognizer(target: self, action: #selector(NCDrawerController.didGestureChanged(_:)))
        g.delegate = self
        self.view.addGestureRecognizer(g)
        
        drawerMenu.addObserver(self, forKeyPath: "center", options: .new, context: nil)
    }
    
    override func viewDidLayoutSubviews() {
        drawerMenu.frame.size.width = drawerSize
        switch drawerDirection {
        case .left,.right:
            __maxLength = (transparent.frame.width + drawerMenu.frame.width)/2
            __minLength = (transparent.frame.width - drawerMenu.frame.width)/2
        case .bottom,.top:
            __maxLength = (transparent.frame.height + drawerMenu.frame.height)/2
            __minLength = (transparent.frame.height - drawerMenu.frame.height)/2
        }
    }
    
    deinit {
        drawerMenu.removeObserver(self, forKeyPath: "center")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let p = change?[.newKey] as? NSValue {
            btnMenuClose.isHidden = false
            let val = abs(p.cgPointValue.x - self.view.center.x)
            btnMenuClose.alpha = 1 - (val - __minLength) / (__maxLength - __minLength)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if isShowingMenu {
            return true
        }else if drawerDirection == .right && gestureRecognizer.location(in: self.view).x > self.view.frame.size.width - 50 {
            return true
        }else if drawerDirection == .left && gestureRecognizer.location(in: self.view).x < 50 {
            return true
        }else if drawerDirection == .top && gestureRecognizer.location(in: self.view).y < 50 {
            return true
        }else if drawerDirection == .bottom && gestureRecognizer.location(in: self.view).y > self.view.frame.size.height - 50 {
            return true
        }
        return false
    }
    
    func didGestureChanged(_ sender:UIPanGestureRecognizer) {
        
        if !enableMenu {
            return
        }
        
        // 点击点的相对隔离
        let p = sender.translation(in: self.view)
        
        // 排除无效操作
        if drawerDirection == .left && (isShowingMenu ? p.x > 0 : p.x < 0) {
            return
        }else if drawerDirection == .right && (isShowingMenu ? p.x < 0 : p.x > 0) {
            return
        }else if drawerDirection == .top && (isShowingMenu ? p.y > 0 : p.y < 0) {
            return
        }else if drawerDirection == .bottom && (isShowingMenu ? p.y < 0 : p.y > 0) {
            return
        }
        
        switch sender.state {
        case .changed:

            var pc = self.view.center
            
            // 先确定移动距离(已限制最大最小区间)
            let disRange = min(max(__minLength, abs(p.x) + __minLength),__maxLength) - __minLength
            let dis:CGFloat
            if isShowingMenu {
                dis = __minLength + disRange
            }else{
                dis = __maxLength - disRange
            }
            switch drawerDirection {
            case .left,.top:
                pc.x -= dis
            default:
                pc.x += dis
            }
            drawerMenu.center = pc
            let scale = 1.0 - disRange/drawerSize * transparentMaxScale
            scaleTransparent(scale: scale)
            
        case .ended:
            
            if abs(p.x) > drawerSize / 3 { //移动范围超过1/3就认定为想改变菜单的显示/关闭
                isShowingMenu = !isShowingMenu
            }
            self.setShowMenu(isShowingMenu, isAnimated: true)
            
        default:
            break
        }
    }
    
    func setShowMenu(_ isShow:Bool, isAnimated:Bool = true){
        var p = self.view.center
        switch drawerDirection {
        case .left,.top:
            p.x -= (self.view.frame.width - drawerSize)/2
            p.x -= isShow ? 0 : drawerSize
        default:
            p.x += (self.view.frame.width - drawerSize)/2
            p.x += isShow ? 0 : drawerSize
        }
        
        let scale:CGFloat = 1.0 - (isShow ? transparentMaxScale : 0)
        
        UIView.animate(withDuration: isAnimated ? 0.3 : 0, animations: {
            self.scaleTransparent(scale: scale)
            self.drawerMenu.center = p
            self.btnMenuClose.alpha = isShow ? 1 :0
        }) { (completed) in
            self.btnMenuClose.isHidden = !isShow
        }
        isShowingMenu = isShow
    }
    
    fileprivate func scaleTransparent(scale:CGFloat) {
        let transform = CATransform3DMakeScale(scale, scale, scale)
        self.transparent.layer.transform = transform
    }
    
    func menuSwitchAction(_ sender:UIButton) {
        setShowMenu(!isShowingMenu, isAnimated: true)
    }
}

extension UIViewController {
    var ncDrawerController:NCDrawerController? {
        get {
            return self.parent as? NCDrawerController
        }
    }
}
