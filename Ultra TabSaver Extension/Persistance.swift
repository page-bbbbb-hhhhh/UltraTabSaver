//
//  window.swift
//  TabSaver Extension
//
//  Created by Matias Morsa on 28/03/2020.
//  Copyright © 2020 Matias Morsa. All rights reserved.
//

import Foundation
import SafariServices

class Persistance {
    
    
    var page:SFSafariPage!
    static let shared = Persistance()
    var date = Date()
    let formatter = DateFormatter()
    var pageWindow:SFSafariWindow!
    var emptyDict = [String:[URL]]()
    var new = true
    var new_flag = 3
    init(){
        if(new){
            
        }
        load()
        UserDefaults.standard.synchronize()
        formatter.dateFormat = "dd.MM.yyyy"
    }
    
    
    func setThis(page: SFSafariPage){
        self.page = page
    }

    func getStringDictionary() -> [String:[String]]{
        var dic2:[String:[String]] = [:]
        for (k,_) in emptyDict{
            dic2[k] = getByKey(key: k).compactMap { $0.absoluteString }
        }
        return dic2
    }
    
    func getURLlist(lista:[URL]) -> [String]{
        var lista2:[String] = []
        for url in  lista{
            lista2.append(url.absoluteString)
        }
        return lista2
    }
    
    
    
    func getStringDate(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: date)
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        let myStringafd = formatter.string(from: yourDate!)
        return myStringafd
    }
    
    func saveThis(){
        if (page != nil){
            page.getPropertiesWithCompletionHandler({ (properties) in
               guard let properties = properties else {
                   self.validationHandler(false, "")
                   return
               }
               
               guard let url = properties.url else {
                   self.validationHandler(false, "")
                   return
               }
               guard url.scheme == "http" || url.scheme == "https" else {
                   self.validationHandler(false, "")
                   return
               }
                                                   
                self.emptyDict[self.getStringDate(date: Date())] = [url]
                NSLog("///////// UNO SALVADO")
             })
        }
        save()
        if(page != nil ){
            NSLog("///////// UNO TRIDJSDAA")
            page!.getContainingTab(completionHandler: { currentTab in
                   NSLog("///////// CURRENT TAB")
                currentTab.getContainingWindow(completionHandler: { window in
                    self.pageWindow  = window
                    window?.getAllTabs(completionHandler: { tab_list in
                        for _ in tab_list{
                            NSLog("///////// UNO TRIDJSDAA")
                               NSWorkspace.shared.open(URL(string:"https://www.google.com")!)
                               if (tab_list.count > 1){
                                   currentTab.close()
                               }else{
                                   NSWorkspace.shared.open(URL(string:"https://www.google.com")!)
                                    currentTab.close()
                               return
                            }

                        }
                    })
                    })
                })
        }
    }
    
    
    func getByKey(key:String) -> [URL] {
        var retorno = [URL(string: "ERROR")!]
        for (k,_) in emptyDict{
            if (k.elementsEqual(key)){
                retorno =  emptyDict[k]!
            }
        }
        return retorno
    }
    
    func saveAll(){
        var flag = true
        let date = getStringDate(date:Date())
        if(page != nil ){
        page!.getContainingTab(completionHandler: { currentTab in
            currentTab.getContainingWindow(completionHandler: { window in
                self.pageWindow  = window
                window?.getAllTabs(completionHandler: { tab_list in
                    var i = 0
                               for tab in tab_list{
                                   tab.getActivePage(completionHandler: { (page) in
                                    guard let page = page else{
                                        self.validationHandler(false, "")
                                        return
                                    }
                                      page.getPropertiesWithCompletionHandler({ (properties) in
                                            guard let properties = properties else {
                                                self.validationHandler(false, "")
                                                return
                                            }
                                            
                                            guard let url = properties.url else {
                                                self.validationHandler(false, "")
                                                return
                                            }
                                            guard url.scheme == "http" || url.scheme == "https" else {
                                                self.validationHandler(false, "")
                                                return
                                            }
                                        if flag{
                                            self.emptyDict[date] = [url]
                                            flag = false
                                        }else{
                                            self.emptyDict[date]?.append(url)
                                        }
                                        self.save()
                                      })
                                    NSWorkspace.shared.open(URL(string:"https://www.google.com")!)
                                    if (i < tab_list.count){
                                        tab.close()
                                        i += 1
                                    }
                                    })
                    }
                })
            })
        })
        }
    }

    func validationHandler(_: Bool,_: String){
        
    }
    
    func getSelected(date:Date){
        
    }
    
    func deleteAll(){
        emptyDict = [:]
        save()
    }
    
    func getAll()-> [String:[URL]] {
        load()
        return self.emptyDict
    }

    func save(){
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            let dic2:[String:[String]] = getStringDictionary()
            var  keyList = [String]()
            for (key,value) in dic2{

                    UserDefaults.standard.setValue(value, forKey: key)
                    keyList.append(key)
            }
            //     let myData = NSKeyedArchiver.archivedData(withRootObject: keys)
            UserDefaults.standard.set(keyList, forKey: "UTSkeys")

            UserDefaults.standard.synchronize()
    }
    
       
    func load(){
        UserDefaults.standard.synchronize()
        let keys:[String] =  UserDefaults.standard.object(forKey: "UTSkeys") as? [String] ?? []
        UserDefaults.standard.synchronize()
       if(!keys.isEmpty){
            for key in keys
            {
                let urls:[String] = UserDefaults.standard.object(forKey: key) as! [String]
                emptyDict[key] = getURLFromString(urls: urls)
            }
        }
    }
    
    func deleteKey(key: String){
        emptyDict.removeValue(forKey: key)
        save()
    }
    
    func renameKey(oldKey:String, newKey:String){
        if(emptyDict.keys.contains(newKey)){
            dialogOK(question: "This name already exist", text: "Try another value")
        }else{
            emptyDict[newKey] = emptyDict[oldKey]
            deleteKey(key: oldKey)
            save()
        }
    }
    
    func addPage(key:String, pageURL:String){
        emptyDict[key]?.append(URL(string:pageURL)!)
        save()
    }
    
    func dialogOK(question: String, text: String) -> Bool {
          let alert = NSAlert()
          alert.messageText = question
          alert.informativeText = text
          alert.alertStyle = .warning
          alert.addButton(withTitle: "OK")
          return alert.runModal() == .alertFirstButtonReturn

      }
    
    func deletePage(key:String, page:String ){
        let index = getStringDictionary()[key]?.firstIndex(of: page) ?? -1
        if (index != -1){
             emptyDict[key]?.remove(at: index)
        }
        save()
    }
    
    
    func getURLFromString(urls:[String]) -> [URL]  {
        var list:[URL] = []
        for url in  urls{
            list.append(URL(string: url)!)
        }
        return list
    }
    
    func getWindow()->SFSafariWindow{
        NSLog("/////////PIDIO LA WINDOW ///////")
        return self.pageWindow
    }
    
    func setWindow(window:SFSafariWindow){
        NSLog("/////////LLEGO ///////")
        self.pageWindow = window
        NSLog("/////////GUARDO LA WINDOW ///////")
    }
    
    func aux(){
        self.page.getContainingTab(completionHandler: { currentTab in
                  currentTab.getContainingWindow(completionHandler: { window in
                    NSLog("/////////LLEGO ///////")
                    self.pageWindow = window!
                    NSLog("/////////LLEGO ///////")
                      window?.getAllTabs(completionHandler: { tab_list in
                          for tab in tab_list{
                              tab.getActivePage(completionHandler: { (page) in
                                  guard let page = page else {
                                      self.validationHandler(false, "")
                                      return
                                  }
                                  page.getPropertiesWithCompletionHandler({ (properties) in
                                      guard let properties = properties else {
                                          self.validationHandler(false, "")
                                          return
                                      }
                                      
                                      guard let url = properties.url else {
                                          self.validationHandler(false, "")
                                          return
                                      }
                                      guard url.scheme == "http" || url.scheme == "https" else {
                                          self.validationHandler(false, "")
                                          return
                                      }
                                      NSLog(url.absoluteString)
                                      self.validationHandler(true, "")
                                  })
                              })
                          }
                      })
                  })
              })
    }
}
