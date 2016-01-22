//
//  Jockey.swift
//  JockeyJS-Swift
//
//  Created by Mrlu-bjhl on 16/1/16.
//  Copyright © 2016年 Mrlu. All rights reserved.
//

import UIKit

public typealias JockeyHandler = (payload:NSDictionary) -> Void
public typealias JockeyAsyncHandler = (webView:UIWebView, payload:NSDictionary, complete:(Void) -> Void) -> Void

/// swift Closures is a Any, and NSMutable must be add a anyObject,
/// so we create a JocketObject contaion the Any.
public class JockeyObject {
    public var block:Any?
    convenience init(block:Any?) {
        self.init()
        self.block = block;
    }
}

/// Jockey is Tool for handle webView data interface
public class Jockey: NSObject {

    public var messageCount:NSNumber = NSNumber(int: 0)
    public var listeners:NSMutableDictionary = NSMutableDictionary()
    public var callbacks:NSMutableDictionary = NSMutableDictionary()
    
    public static let shareInstance = Jockey();
    
    private override init() {}
    
    public class func on(type type:String!, perform handler:JockeyHandler?) -> Void {
        
        let extended:JockeyAsyncHandler = {
            (webView, payload, complete) in
            handler!(payload: payload)
            complete()
        }
        self.on(type: type, performAsync: extended)
    }
    
    public class func on(type type:String!, performAsync handler:JockeyAsyncHandler?) -> Void {
        
        let instance = Jockey.shareInstance
        let listeners = instance.listeners
        var listenerList:NSMutableArray? = listeners.objectForKey(type) as? NSMutableArray
        if listenerList == nil {
            listenerList = NSMutableArray()
            instance.listeners.setValue(listenerList, forKey: type)
        }
        let jockeyObj = JockeyObject(block: handler)
        listenerList!.addObject(jockeyObj)
    }
    
    public class func off(type type:NSString!) -> Void {
        let instance = Jockey.shareInstance
        let listeners = instance.listeners
        listeners.removeObjectForKey(type)
    }
    
    public class func send(type type:String!, payload:AnyObject?, webView:UIWebView?) -> Void {
        self.send(type: type, payload: payload, webView: webView, perform: nil)
    }
    
    public class func send(type type:String!, payload:AnyObject?, webView:UIWebView?, perform complete:((Void) -> Void)?) -> Void {
        let jockey = Jockey.shareInstance
        let messageId = jockey.messageCount;
        if (complete != nil) {
            let jockeyObj = JockeyObject(block: complete)
            jockey.callbacks.setValue(jockeyObj, forKey: messageId.stringValue);
        }
        
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(payload!, options: NSJSONWritingOptions.PrettyPrinted)
        let jsonString = NSString(data: jsonData!, encoding: NSUTF8StringEncoding)
        let javascript = NSString(format: "Jockey.trigger(\"%@\", %li, %@);", type, messageId.integerValue, jsonString!)
        webView?.stringByEvaluatingJavaScriptFromString(javascript as String)
        jockey.messageCount = NSNumber(integer:jockey.messageCount.integerValue + 1)
    }
    
    public class func webView(webView webView:UIWebView!, url:NSURL?) -> Bool {
        guard let url = url else {
            return false
        }
        let scheme:NSString = url.scheme
        
        if scheme.isEqualToString("jockey") {
            let eventType = url.host
            let messageId = url.path!.substringFromIndex(url.path!.startIndex.advancedBy(1))
            let query = url.query
            let jsonString = query?.stringByRemovingPercentEncoding
            let JSON:NSDictionary? = try? NSJSONSerialization.JSONObjectWithData((jsonString?.dataUsingEncoding(NSUTF8StringEncoding))!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            if (eventType! as NSString).isEqualToString("event") {
                shareInstance.triggerEvent(fromWebView: webView, data: JSON!)
            } else if (eventType! as NSString).isEqualToString("callback") {
                shareInstance.triggerCallback(forMessage: messageId)
            }
            return false
        }
        return true;
    }
    
    
    private func triggerEvent(fromWebView webView:UIWebView, data:NSDictionary) -> Void
    {
        let listeners:NSDictionary? = Jockey.shareInstance.listeners
        let messageId = data.objectForKey("id")?.stringValue
        let type = data.objectForKey("type") as! String
        let payload = data.objectForKey("payload") as! NSDictionary
        let listenerList:NSArray? = listeners?.objectForKey(type) as? NSArray
    
        var executedCount = 0
        let complete:(Void) -> Void = {
            executedCount += 1
            if executedCount >= listenerList?.count {
                Jockey.shareInstance.triggerCallback(onWebView: webView, forMessage: messageId!)
            }
        }
        
        if let listenerList = listenerList {
            for var index = 0; index < listenerList.count; index++ {
                let handle:JockeyAsyncHandler = (listenerList.objectAtIndex(index) as! JockeyObject).block as! JockeyAsyncHandler
                handle(webView: webView, payload: payload, complete: complete)
            }
        }
    }
    
    private func triggerCallback(onWebView webView:UIWebView, forMessage messageId:String) -> Void {
        let javascript = NSString(format: "Jockey.triggerCallback(%@);", messageId)
        webView.stringByEvaluatingJavaScriptFromString(javascript as String)
    }
    
    public func triggerCallback(forMessage messageId:String) -> Void {
        let messageIdString = messageId
        let obj = self.callbacks.objectForKey(messageIdString)
        if let obj = obj {
            let callback:(Void) -> Void = (obj as! JockeyObject).block as! (Void) -> Void
            callback()
        }
        
        self.callbacks.removeObjectForKey(messageIdString)
    }
}
