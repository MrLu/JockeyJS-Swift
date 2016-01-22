//
//  ViewController.swift
//  JockeyJS-Swift
//
//  Created by Mrlu-bjhl on 16/1/16.
//  Copyright © 2016年 Mrlu. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.refresh()
        
//        // Listen for a JS event.
//        
//        [Jockey on:@"toggle-fullscreen" perform:^(NSDictionary *payload) {
//        [self toggleFullscreen:nil withDuration:0.3];
//        }];
//        
//        [Jockey on:@"toggle-fullscreen-with-callback" performAsync:^(UIWebView *webView, NSDictionary *payload, void (^complete)()) {
//        NSTimeInterval duration = [[payload objectForKey:@"duration"] integerValue];
//        
//        [self toggleFullscreen:complete withDuration:duration];
//        }];
        
        Jockey.on(type: "log") { (payload) -> Void in
            NSLog("\"log\" received, payload = %@", payload)
        }
        
        Jockey.on(type: "toggle-fullscreen", perform: { (payload) -> Void in
//            self.toggleFullscreen(complete, duration: duration!)
            NSLog("\"toggle-fullscreen\" received, payload = %@", payload)
        })
        
        Jockey.on(type: "toggle-fullscreen-with-callback") { (webView, payload, complete) -> Void in
            let duration = payload.objectForKey("duration")?.timeInterval
            self.toggleFullscreen(complete, duration: duration!)
        }
        
        self.webView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refresh() {
        let htmlFile = NSBundle.mainBundle().pathForResource("index", ofType: "html")
        let path = NSBundle.mainBundle().bundlePath
        let baseURL = NSURL.fileURLWithPath(path)
        
        let htmlString:NSString = try! NSString(contentsOfFile: htmlFile!, encoding: NSUTF8StringEncoding)
            
        self.webView.loadHTMLString(htmlString.description, baseURL: baseURL)
    }
    
    @IBAction func colorButtonPressed(sender:UIBarButtonItem) -> Void {
    
        let payload = ["color": "#000000"] as NSDictionary;
    
        Jockey.send(type:"color-change", payload:payload, webView:self.webView)
    }
    
    func toggleFullscreen(complete:(Void)->(Void), duration:NSTimeInterval) -> Void{
        NSLog("全屏显示")
    }
    
    @IBAction func showImageButtonPressed(sender: AnyObject) {
        let payload = ["feed":"http://www.google.com/doodles/doodles.xml"]
        
        Jockey .send(type: "show-image", payload: payload, webView: self.webView) { (Void) -> Void in
            let alertController = UIAlertController(title: "Image loaded", message: "callback in iOS from JS event", preferredStyle: .Alert)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func refreshButtonPressed(sender: AnyObject) {
        self.refresh()
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return Jockey.webView(webView: webView, url: request.URL)
    }
}

