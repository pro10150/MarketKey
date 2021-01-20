//
//  Model.swift
//  Market Key
//
//  Created by นพคุณ อนันตกิจถาวร on 15/1/2564 BE.
//

import Foundation
import UIKit

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    static func *(recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
            let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
            let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
            let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
            let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
            let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

            return (month: month, day: day, hour: hour, minute: minute, second: second)
        }
}




class stock{
    var observeStockName: String
    var compareStockName: String
    private let headers = [
        "x-rapidapi-key": "e4c4ed5bedmsh218b396bff1ac9cp1db50ajsn545e33365078",
        "x-rapidapi-host": "yahoo-finance15.p.rapidapi.com"
    ]
    public var observeStock = [String: Double]()
    public var compareStock = [String: Double]()
    private var addedDate: Date
    
    func formatting(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "DD-MM-YYYY"
        return formatter.string(from: date)
    }
    
    init(observeStockName: String, compareStockName: String) {
        self.observeStockName = observeStockName
        self.compareStockName = compareStockName
        UserDefaults.standard.setValue(observeStock, forKey: "observeStockValue")
        UserDefaults.standard.setValue(compareStock, forKey: "compareStockValue")
        addedDate = Date()
        let stringDate: String = formatting(date: addedDate)
        UserDefaults.standard.setValue(addedDate, forKey: "addedDateValue")
    }
    
    init() {
        self.observeStockName = UserDefaults.standard.string(forKey: "observeStockValue")!
        self.compareStockName = UserDefaults.standard.string(forKey: "compareStockValue")!
        let isoDate = UserDefaults.standard.string(forKey: "addedDateValue")
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from:isoDate!)!
        let dateDifference = Date() * date
        self.addedDate = date
    }
    func getDay() -> Int{
        let isoDate = UserDefaults.standard.string(forKey: "addedDateValue")
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from:isoDate!)!
        let dateDifference = Date() * date
        return dateDifference.day! + 1
    }
    func getObserveStock(){
        // get observe stock price
        let observeRequest = NSMutableURLRequest(url: NSURL(string: "https://yahoo-finance15.p.rapidapi.com/api/yahoo/hi/history/"+UserDefaults.standard.string(forKey: "observeStockValue")!+".BK/1d")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        observeRequest.httpMethod = "GET"
        observeRequest.allHTTPHeaderFields = headers



        //API key need to be claim in AlphaVantage
        let session = URLSession.shared
        //print("Yeet")
        var dataTask = session.dataTask(with: observeRequest as URLRequest, completionHandler: { (data, response, error) in
                //print("Yeah")
                //var observeStock: [String: Double]

                guard let data = data else {return}
                    
                //print("Hello")
                do{
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject
                    var symbols: String
                        
                    if let information = json["meta"] as? NSDictionary{
                        if let symbol = information["symbol"]{
                            symbols = symbol as! String
                            print(symbols)
                            if let range = symbols.range(of: ":"){
                                symbols = String(symbols[range.upperBound...])
                            }
                        }
                    }
                    var i = 1
                    var dayValue = i
                    var day = self.getDay()
                    repeat{
                        
                        var currentDateTime = Calendar.current.date(byAdding: .day, value: -dayValue, to: Date())!
                        var flag: Bool = false
                        if let prices = json["items"] as? NSDictionary{
                            guard let timeArray = prices as? [String: AnyObject] else {return}
                            for (_, value) in timeArray{
                                guard let stockDate = value["date"] as? String else {return}
                                guard let price = value["close"] as? Double else {return}
                                
                                //print("\(stockDate): \(price)")
                                if stockDate == self.formatting(date: currentDateTime){
                                    //print(prices)
                                    print("Found it!")
                                    print("price: \(price)")
                                    self.observeStock[stockDate] = price
                                    //print(observeStock[stockDate])
                                    flag = true
                                    i += 1
                                    dayValue += 1
                                    break
                                }
                            }
                            
                            if flag == false {
                                dayValue += 1
                            }/*
                            if flag == true{
                                flag = false
                                continue
                            }*/
                        }
                        
                    }while i <= day
                }catch let err{
                    print(err)
                }
            })
        dataTask.resume()
    }
    
    func getCompareStock(){
        let compareRequest = NSMutableURLRequest(url: NSURL(string: "https://yahoo-finance15.p.rapidapi.com/api/yahoo/hi/history/"+UserDefaults.standard.string(forKey: "compareStockValue")!+".BK/1d")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        compareRequest.httpMethod = "GET"
        compareRequest.allHTTPHeaderFields = headers



        //API key need to be claim in AlphaVantage
        //let session = URLSession.shared
        //print("Yeet")
        let session = URLSession.shared
        var compareDataTask = session.dataTask(with: compareRequest as URLRequest, completionHandler: { (data, response, error) in
                //print("Yeah")
                //var observeStock: [String: Double]

                guard let data = data else {return}
                    
                //print("Hello")
                do{
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject
                    var symbols: String
                        
                    if let information = json["meta"] as? NSDictionary{
                        if let symbol = information["symbol"]{
                            symbols = symbol as! String
                            print(symbols)
                            if let range = symbols.range(of: ":"){
                                symbols = String(symbols[range.upperBound...])
                            }
                        }
                    }
                    var i = 1
                    var dayValue = i
                    var day = self.getDay()
                    repeat{
                        print("Day: \(i)")
                        var currentDateTime = Calendar.current.date(byAdding: .day, value: -dayValue, to: Date())!
                        //print(formatter.string(from: currentDateTime))
                        var flag: Bool = false
                        if let prices = json["items"] as? NSDictionary{
                            guard let timeArray = prices as? [String: AnyObject] else {return}
                            for (_, value) in timeArray{
                                guard let stockDate = value["date"] as? String else {return}
                                guard let price = value["close"] as? Double else {return}
                                
                                //print("\(stockDate): \(price)")
                                if stockDate == self.formatting(date: currentDateTime){
                                    //print(prices)
                                    print("Found it!")
                                    print("price: \(price)")
                                    self.compareStock[stockDate] = price
                                    //print(observeStock[stockDate])
                                    flag = true
                                    i += 1
                                    dayValue += 1
                                    break
                                }
                            }
                            
                            if flag == false {
                                dayValue += 1
                            }/*
                            if flag == true{
                                flag = false
                                continue
                            }*/
                        }
                        
                    }while i <= day
                }catch let err{
                    print(err)
                }
            })
        compareDataTask.resume()
    }
    
}
