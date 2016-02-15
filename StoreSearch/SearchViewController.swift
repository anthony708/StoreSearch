//
//  ViewController.swift
//  StoreSearch
//
//  Created by ZhuDuan on 16/2/12.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit

struct TableViewCellIdentifiers {
    static let searchResultCell = "SearchResultCell"
    static let nothingFoundCell = "NothingFoundCell"
    static let loadingCell = "LoadingCell"
}

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        searchBar.becomeFirstResponder()
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        let cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        tableView.rowHeight = 80
        
        let nothingFoundCellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(nothingFoundCellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        let loadingCellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(loadingCellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        // The keyboard will hide until tap the search bar
        
        if ((searchBar.text?.isEmpty) != nil) {
            searchBar.resignFirstResponder()
            hasSearched = true
            isLoading = true
            tableView.reloadData()
            
            let url = urlWithSearchText(searchBar.text!)
            if let jsonString = performStoreRequestWithURL(url) {
                if let dictionary = parseJSON(jsonString) {
                    searchResults = parseDictionary(dictionary)
                    
                    searchResults.sortInPlace(<)
                    
                    isLoading = false
                    tableView.reloadData()
                    return
                }
            }
        }
        
        showNetworkError()
    }
    
    // status bar is unified with search bar
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as UITableViewCell
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath)
            
        } else {
        
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell) as! SearchResultCell
        
            if searchResults.count == 0 {
                cell.nameLabel?.text = "(Nothing Found)"
                cell.artistNameLabel?.text = ""
            } else {
                let searchResult = searchResults[indexPath.row]
                cell.nameLabel?.text = searchResult.name
                if searchResult.artistName.isEmpty {
                    cell.artistNameLabel.text = "Unknown"
                } else {
                    cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, kindForDisplay(searchResult.kind))
                }
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
    func urlWithSearchText(searchText: String) -> NSURL {
        
        let escapeSearchText = searchText.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=200", escapeSearchText!)
        let url = NSURL(string: urlString)
        return url!
    }
    
    func performStoreRequestWithURL(url: NSURL) -> String? {
        if let data = try? String(contentsOfURL: url, encoding: NSUTF8StringEncoding) {
            return data
        } else {
            print("Error")
        }
        return nil
    }
    
    func parseJSON(data: String) -> [String: AnyObject]? {
        
        if let jsonData = data.dataUsingEncoding(NSUTF8StringEncoding) {
            let json = try! NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
            return json as? [String : AnyObject]
        }
        
        return nil
    }
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult]{
        
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
    
    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func kindForDisplay(kind: String) -> String {
        switch kind {
        case "album" : return "Album"
        case "audiobook": return "Audio Book"
        case "book": return "Book"
        case "ebook": return "E-Book"
        case "feature-movie": return "Movie"
        case "music-video": return "Music Video"
        case "podcast": return "Podcast"
        case "software": return "App"
        case "song": return "Song"
        case "tv-episode": return "TV Episode"
        default: return kind
        }
    }
}
