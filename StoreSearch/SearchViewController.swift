//
//  ViewController.swift
//  StoreSearch
//
//  Created by ZhuDuan on 16/2/12.
//  Copyright © 2016年 Anthony. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        
        performSearch()
    }
    
    let search = Search()
    
    var landscapeViewController: LandscapeViewController?
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        tableView.rowHeight = 80
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
        search.performSearchForText(searchBar.text!, category: segmentedControl.selectedSegmentIndex, completion: { success in
            if !success {
                self.showNetworkError()
            }
            
            self.tableView.reloadData()
        })
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    // status bar is unified with search bar
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if search.isLoading {
            return 1
        } else if !search.hasSearched {
            return 0
        } else if search.searchResults.count == 0 {
            return 1
        } else {
            return search.searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if search.isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as UITableViewCell
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
            
        } else if search.searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath)
            
        } else {
        
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell) as! SearchResultCell
        
            let searchResult = search.searchResults[indexPath.row]
            cell.configureForSearchResult(searchResult)
 
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("ShowDetail", sender: indexPath)
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if search.searchResults.count == 0 || search.isLoading {
            return nil
        } else {
            return indexPath
        }
    }
        
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destinationViewController as! DetailViewController
            let indexPath = sender as! NSIndexPath
            let searchResult = search.searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .Compact:
            showLandscapeViewWithCoordinator(coordinator)
        case .Regular, .Unspecified:
            hideLandscapeViewWithCoordinator(coordinator)
        }
    }
    
    func showLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        
        precondition(landscapeViewController == nil)
        
        landscapeViewController = (storyboard?.instantiateViewControllerWithIdentifier("LandscapeViewController") as! LandscapeViewController)
        if let controller = landscapeViewController {
            controller.search = search
            
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }, completion: { _ in
                controller.didMoveToParentViewController(self)
            })
        }
    }
    
    func hideLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            controller.willMoveToParentViewController(nil)
            
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.landscapeViewController = nil
            })
            
        }
    }
}
