//
//  SearchViewController.swift
//  ArtistsPresentetion
//
//  Created by Андрей Романюк on 2/15/19.
//  Copyright © 2019 Андрей Романюк. All rights reserved.
//

import UIKit
import SafariServices
import CoreData

class SearchViewController: UIViewController {

    // MARK: - Vars
    static let shared = SearchViewController()
    var currentArtist:Artist?
    var currentSearchText = String()
    let context = CoreDataManager.instance.persistentContainer.viewContext
    var isInDataBase = false

    
    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!{
        didSet{
            searchBar.delegate = self
        }
        
    }
    @IBOutlet weak var searchResultsLabel: UILabel!
    @IBOutlet weak var searchSpinner: UIActivityIndicatorView!
    @IBOutlet weak var presentationView: UIView!

    @IBOutlet weak var artistImage: UIImageView!{
        didSet{
            artistImage.clipsToBounds = true
        }
    }
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var addAndRemoveButton: UIButton! {
        didSet {
            addAndRemoveButton.clipsToBounds = true
        }
    }
    @IBOutlet weak var resultButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultView: UIView!
    
    // MARK: - Actions
    @IBAction func loadFacebookPage(_ sender: UIButton) {
        if let artist = SearchViewController.shared.currentArtist, let facebook = artist.getFacebookPage(){
            if let url = URL(string: facebook){
                InternetDataManager.openSafariPage(withUrl: url, byController: self)
            }
        }
    }
    
    @IBAction func addToFavorites(_ sender: UIButton) {
        if SearchViewController.shared.isInDataBase {
            CoreDataManager.instance.deleteObject(withName: artistNameLabel.text!, forEntity: "FavoriteArtist") {
                //во многих местах создаешь картинку для кнопки, можно создавать один экземпляр и этого нам будет достаточно. например так:
//                enum ButtonImage {
//                    case add
//                    case remove
//                    var image: UIImage {
//                        switch self {
//                        case .add: return UIImage(named: "add.png")!
//                        case .remove: return UIImage(named: "remove.png")!
//                        }
//                    }
//                  }
                if let image = UIImage(named: "addButton.svg") {
                    self.addAndRemoveButton.setImage(image, for: .normal)
                }
                SearchViewController.shared.isInDataBase = false
                if let image = UIImage(named: "removed.svg") {
                    self.resultButton.setImage(image, for: .normal)
                }
                resultLabel.text = StringConstants.Search.removed
                animateResult()
            }
        } else {
            if InternetDataManager.shared.isConnectedToNetwork(){
                CoreDataManager.instance.addFavoriteArtist(withName: (SearchViewController.shared.currentArtist?.getName())!, withID: (SearchViewController.shared.currentArtist?.getID())!, withEventsCount: (SearchViewController.shared.currentArtist?.getUpcomingEventCount())!, withImageDataURL: (SearchViewController.shared.currentArtist?.getThumbUrl())!) {
                    if let image = UIImage(named: "remove.svg") {
                        self.addAndRemoveButton.setImage(image, for: .normal)
                    }
                    if let image = UIImage(named: "added.svg") {
                        self.resultButton.setImage(image, for: .normal)
                    }
                    resultLabel.text = StringConstants.Search.added
                    animateResult()
                    SearchViewController.shared.isInDataBase = true
                }
            } else {
                Alerts.presentConnectionAlert(viewController: self)
            }
        }
    }
    
    @IBAction func showEvents(_ sender: UIButton) {
        if InternetDataManager.shared.isConnectedToNetwork() {
            let eventsStoryboard = UIStoryboard(name: "Events", bundle: nil)
            let eventsViewController = eventsStoryboard.instantiateViewController(withIdentifier: "viewController")
            self.navigationController?.pushViewController(eventsViewController, animated: true)
            EventsViewController.shared.artist = (SearchViewController.shared.currentArtist!.getName(), SearchViewController.shared.currentArtist!.getUpcomingEventCount())
        } else {
            Alerts.presentConnectionAlert(viewController: self)
        }
    }
    
    @IBAction func presentEventsOnMap(_ sender: UIButton) {
        InternetDataManager.shared.getEvents(forArtist: (SearchViewController.shared.currentArtist?.getName())!, forDate: nil, viewController: self) { (error, events) in
            if error != nil{
                Alerts.presentFailedDataLoadingAlert(viewController: self)
            } else if events != nil, events?.count != 0 {
                MapViewController.shared.currentArtistName = SearchViewController.shared.currentArtist?.getName()
                DispatchQueue.main.async {
                    MapViewController.shared.needSetCenterValue = false
                    MapViewController.shared.presentingEvents = events!
                    MapViewController.shared.currentArtistId = SearchViewController.shared.currentArtist?.getID()
                    self.tabBarController?.selectedIndex = 2
                }
            } else if events != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: StringConstants.ArtistEvents.events, message: StringConstants.ArtistEvents.noEvents, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                Alerts.presentFailedDataLoadingAlert(viewController: self)
            }
        }
    }
    
    
    // MARK: - Search Bar & Keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchSpinner.startAnimating()
        searchAndPresentArtist()
    }
    
    
    // MARK: - View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if !SearchViewController.shared.isInDataBase {
            if let image = UIImage(named: "addButton.svg") {
                self.addAndRemoveButton.setImage(image, for: .normal)
            }
        }
        navigationController?.view.layoutSubviews()

    }

    //MARK: - Gestures
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        if searchBar.isFirstResponder{
            searchBar.resignFirstResponder()
        }
    }
    
    @IBAction func swipeGesture(_ sender: UISwipeGestureRecognizer) {
        if searchBar.isFirstResponder{
            searchBar.resignFirstResponder()
        }
    }
    
    // MARK: - MyTools
    func hidePresentationView() {
        presentationView.isHidden = true
        presentationView.alpha = 0.0
        if !searchResultsLabel.isHidden {
            searchResultsLabel.isHidden = true
        }
    }
    
    func configureAndShowPresentationView() {
        self.searchSpinner.stopAnimating()
        self.presentationView.isHidden = false
        self.searchResultsLabel.isHidden = true
        SearchViewController.shared.isInDataBase = CoreDataManager.instance.objectIsInDataBase(objectName: self.artistNameLabel.text!, forEntity: "FavoriteArtist")
        if SearchViewController.shared.isInDataBase {
            if let image = UIImage(named: "remove.svg") {
                self.addAndRemoveButton.setImage(image, for: .normal)
            }
        } else {
            if let image = UIImage(named: "addButton.svg") {
                self.addAndRemoveButton.setImage(image, for: .normal)
            }
        }
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0.0, options: .allowUserInteraction, animations: {
            self.presentationView.alpha = 1.0
        }, completion: nil)
    }
    
    func searchAndPresentArtist(){
        hidePresentationView()
        InternetDataManager.shared.getArtist(viewController: self, searchText: SearchViewController.shared.currentSearchText) { (error, artist) in
            if SearchViewController.shared.currentSearchText.count > 2 {
                if error != nil {
                    DispatchQueue.main.async {
                        Alerts.presentFailedDataLoadingAlert(viewController: self)
                        self.searchSpinner.stopAnimating()
                    }
                } else if let gotArtist = artist {
                    SearchViewController.shared.currentArtist = artist
                    if let imageUrl = URL(string: gotArtist.getImageUrl()), let imageData = try? Data(contentsOf: imageUrl){
                        if let image = UIImage(data: imageData){
                            DispatchQueue.main.async {
                                self.artistImage.image = image
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        if (gotArtist.getFacebookPage()) != nil{
                            self.facebookButton.isEnabled = true
                        } else {
                            self.facebookButton.isEnabled = false
                        }
                        self.artistNameLabel.text = gotArtist.getName()
                        self.configureAndShowPresentationView()
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self.searchSpinner.stopAnimating()
                        self.searchResultsLabel.text = StringConstants.Search.noResults
                        self.searchResultsLabel.isHidden = false
                    }
                }
            }
        }
    }
    
    func animateResult() {
        self.resultView.isHidden = false
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.4, delay: 0.0, options: .allowUserInteraction, animations: {
            self.resultView.alpha = 1.0
        }) { (position) in
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.4, delay: 1.0, options: .allowUserInteraction, animations: {
                self.resultView.alpha = 0.0
            }){ (position) in
                self.resultView.isHidden = true
            }
        }
    }
    
    func showResultLabel() {
        SearchViewController.shared.currentArtist = nil
        presentationView.isHidden = true
        presentationView.alpha = 0.0
        searchSpinner.stopAnimating()
        searchResultsLabel.isHidden = false
    }
}


// MARK: - Extension
extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0{
            showResultLabel()
            searchResultsLabel.text = StringConstants.Search.search
        }else if (1..<3).contains(searchText.count){
            showResultLabel()
            searchResultsLabel.text = StringConstants.Search.enterName
            if !InternetDataManager.shared.isConnectedToNetwork() {
                Alerts.presentConnectionAlert(viewController: self)
            }
            SearchViewController.shared.currentSearchText = searchText
        }else{
            searchSpinner.startAnimating()
            if SearchViewController.shared.currentSearchText != searchText {
                SearchViewController.shared.currentSearchText = searchText
                searchAndPresentArtist()
            }
        }
    }
}

