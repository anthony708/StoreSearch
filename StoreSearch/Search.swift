//
//  Search.swift
//  StoreSearch
//
//  Created by ZhuDuan on 16/3/1.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import Foundation

typealias SearchComplete = (Bool) -> Void

class Search {
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    private var dataTask: NSURLSessionDataTask? = nil
    
    func performSearchForText(text: String, category: Int, completion: SearchComplete) {
        if !text.isEmpty {
            dataTask?.cancel()
            
            isLoading = true
            hasSearched = true
            searchResults = [SearchResult]()
            
            let url = urlWithSearchText(text, category: category)
            
            let session = NSURLSession.sharedSession()
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                
                var success = false
                
                if let error = error {
                    if error.code == -999 { return }
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let dictionary = self.parseJSON(data!) {
                            self.searchResults = self.parseDictionary(dictionary)
                            self.searchResults.sortInPlace(<)
                            
                            print("Success!")
                            self.isLoading = false
                            success = true
                        }
                    }
                }
                
                if !success {
                    self.hasSearched = false
                    self.isLoading = false
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    completion(success)
                }
            })
            
            dataTask?.resume()
        }
    }
    
    private func urlWithSearchText(searchText: String, category: Int) -> NSURL {
        
        var entityName: String
        switch category {
        case 1: entityName = "musicTrack"
        case 2: entityName = "software"
        case 3: entityName = "ebook"
        default: entityName = ""
        }
        
        let escapeSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapeSearchText!, entityName)
        let url = NSURL(string: urlString)
        return url!
    }
    
    private func parseJSON(data: NSData) -> [String: AnyObject]? {
        
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String : AnyObject]
        return json
        
    }
    
    private func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult]{
        
        var searchResults = [SearchResult]()
        
        if let array: AnyObject = dictionary["results"] {
            for resultDict in array as! [AnyObject] {
                if let resultDict = resultDict as? [String: AnyObject] {
                    
                    var searchResult: SearchResult?
                    if let wrapperType = resultDict["wrapperType"] as? String {
                        
                        switch wrapperType {
                        case "track":
                            searchResult = parseTrack(resultDict)
                        case "audiobook":
                            searchResult = parseAudioBook(resultDict)
                        case "software":
                            searchResult = parseSoftware(resultDict)
                        default:
                            break
                        }
                    } else if let kind = resultDict["kind"] as? String {
                        if kind == "ebook" {
                            searchResult = parseEBook(resultDict)
                        }
                    }
                    
                    if let result = searchResult {
                        searchResults.append(result)
                    }
                    
                } else {
                    print("Expected a dictionary")
                }
            }
        } else {
            print("Expected results array")
        }
        
        return searchResults
    }
    
    private func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["trackPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["collectionPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre as String
        }
        return searchResult
    }
    
    private func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    private func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        //            if let genres: AnyObject? = dictionary["genres"] {
        //                searchResult.genre = genres.joinWithSeparator(",")
        //                print("\(genres)")
        //            }
        return searchResult
    }

}