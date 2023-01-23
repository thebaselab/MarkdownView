import UIKit
import WebKit

/**
 Markdown View for iOS.
 
 - Note: [How to get height of entire document with javascript](https://stackoverflow.com/questions/1145850/how-to-get-height-of-entire-document-with-javascript)
 */
open class MarkdownView: UIView {

  private var webView: WKWebView?
  
  private var darkBackground: UIColor = UIColor(hex: "#1E1E1E")!
  private var lightBackground: UIColor = UIColor(hex: "#fdfdfd")!
    
  fileprivate var intrinsicContentHeight: CGFloat? {
    didSet {
      self.invalidateIntrinsicContentSize()
    }
  }

  @objc public var isScrollEnabled: Bool = true {

    didSet {
      webView?.scrollView.isScrollEnabled = isScrollEnabled
    }

  }

  @objc public var onTouchLink: ((URLRequest) -> Bool)?

  @objc public var onRendered: ((CGFloat) -> Void)?

  public convenience init() {
    self.init(frame: CGRect.zero)
  }

  override init (frame: CGRect) {
    super.init(frame : frame)
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  open override var intrinsicContentSize: CGSize {
    if let height = self.intrinsicContentHeight {
      return CGSize(width: UIView.noIntrinsicMetric, height: height)
    } else {
      return CGSize.zero
    }
  }
    
    @objc public func changeBackgroundColor(color: UIColor){
        self.webView?.backgroundColor = color
        self.webView?.scrollView.backgroundColor = color
    }
    
    public func removeDragDropInteraction(){
        self.webView?.removeUIDragDropInteraction()
    }

    @objc public func load(markdown: String?, enableImage: Bool = true, backgroundColor: UIColor) {
    guard let markdown = markdown else { return }

    if htmlURL != nil {
      let escapedMarkdown = self.escape(markdown: markdown) ?? ""
      let imageOption = enableImage ? "true" : "false"
      let script = "window.showMarkdown('\(escapedMarkdown)', \(imageOption));"
      let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

      let controller = WKUserContentController()
      controller.addUserScript(userScript)

      let configuration = WKWebViewConfiguration()
      configuration.userContentController = controller

      let wv = WKWebView(frame: self.bounds, configuration: configuration)
      wv.scrollView.isScrollEnabled = self.isScrollEnabled
      wv.translatesAutoresizingMaskIntoConstraints = false
      wv.navigationDelegate = self
      addSubview(wv)
      wv.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      wv.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      wv.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
      wv.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
      wv.isOpaque = false
      wv.backgroundColor = backgroundColor
      wv.scrollView.backgroundColor = backgroundColor
      wv.allowsLinkPreview = false

      self.webView = wv
        
        
        let template =
"""
<!doctype html>
<html>
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
        <link rel="stylesheet" href="./main.css" />
        \("<style>body{background-color: transparent;}</style>")
        <script src="./main.js"></script>
    </head>
    <body>
        <div class="content" id="contents"></div>
    </body>
</html>
"""
        wv.loadHTMLString(template, baseURL: htmlURL)
    } else {
      // TODO: raise error
    }
  }
    
//    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        if traitCollection.userInterfaceStyle == .dark{
//            self.webView?.backgroundColor = darkBackground
//            self.webView?.scrollView.backgroundColor = darkBackground
//        }else{
//            self.webView?.backgroundColor = lightBackground
//            self.webView?.scrollView.backgroundColor = lightBackground
//        }
//    }

  private func escape(markdown: String) -> String? {
    return markdown.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)
  }

}

extension MarkdownView: WKNavigationDelegate {

  public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    
    switch navigationAction.navigationType {
    case .linkActivated:
      if let onTouchLink = onTouchLink, onTouchLink(navigationAction.request) {
        decisionHandler(.allow)
      } else {
        decisionHandler(.cancel)
      }
    default:
      decisionHandler(.allow)
    }

  }

}

extension UIColor {
    public convenience init?(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
}

extension WKWebView {
    func removeUIDragDropInteraction(){
        func findInteractionView(in subviews: [UIView]) -> UIView? {
            for subview in subviews {
                for interaction in subview.interactions {
                    if interaction is UIDragInteraction {
                        return subview
                    }
                }
                return findInteractionView(in: subview.subviews)
            }
            return nil
        }
        
        if let interactionView = findInteractionView(in: subviews) {
            for interaction in interactionView.interactions {
                if interaction is UIDragInteraction || interaction is UIDropInteraction {
                    interactionView.removeInteraction(interaction)
                }
            }
        }
    }
}
