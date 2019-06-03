//
//  ViewController.swift
//  TheMovieDB_ActorSearch
//
//  Created by Basak Ozdemir on 3.06.2019.
//  Copyright © 2019 MacBook. All rights reserved.
//

import UIKit
class ViewController: UIViewController, UITableViewDelegate, UISearchResultsUpdating {
    
    var actors: [Actor] = []
    var filteredActors = [Actor]()
    let group = DispatchGroup()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    enum JSONError: String, Error {
        case NoData = "ERROR: no data"
        case ConversionFailed = "ERROR: conversion from JSON failed"
    }
    
    func jsonParser() {
        
        let urlPath = "https://api.themoviedb.org/3/person/popular?api_key=5aed84127428de1d68f1e2c80f3aa479"
        guard let endpoint = URL(string: urlPath) else {
            print("Error creating endpoint")
            return
        }
        URLSession.shared.dataTask(with: endpoint) { (data, response, error) in
            do {
                guard let data = data else {
                    throw JSONError.NoData
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary else {
                    throw JSONError.ConversionFailed
                }
                self.group.enter()
                let results = json["results"]
                if let array = results as? [Any] {
                    for object in array {
                        // access all objects in array
                        var temp_actor = Actor()
                        if let dictionary = object as? [String: Any] {
                            if let name = dictionary["name"] as? String {
                                // access individual value in dictionary
                                temp_actor.name = name
                            }
                            if let popularity = dictionary["popularity"] as? Double {
                                // access individual value in dictionary
                                temp_actor.popularity = popularity
                            }
                            if let profile_path = dictionary["profile_path"] as? String {
                                // access individual value in dictionary
                                temp_actor.profile_path = profile_path
                            }
                        }
                        self.actors.append(temp_actor)
                    }
                }
            } catch let error as JSONError {
                print(error.rawValue)
            } catch let error as NSError {
                print(error.debugDescription)
            }
            self.group.leave()
            }.resume()
        
        
    }
    
    weak var tableView: UITableView!
    
    override func loadView() {
        super.loadView()
        
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        NSLayoutConstraint.activate([
            self.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: tableView.topAnchor),
            self.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            ])
        self.tableView = tableView
        
        //request
        jsonParser()
        
        group.notify(queue: .main) {
            print(self.actors)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //append cells after group job gets done
        group.notify(queue: .main) {
            self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
            self.tableView.dataSource = self
            
            self.filteredActors = self.actors
            self.searchController.searchResultsUpdater = self
            self.searchController.dimsBackgroundDuringPresentation = false
            self.definesPresentationContext = true
            self.tableView.tableHeaderView = self.searchController.searchBar
        }
        
        
    }
}
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredActors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //init cell object
        var cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell = UITableViewCell(style: UITableViewCell.CellStyle.value1,
                               reuseIdentifier: "UITableViewCell")
        
        let actor = self.filteredActors[indexPath.item] //get actor object for each cell
        cell.textLabel?.text = actor.name //set actor name
        
        //prepare image url for actor
        let photoURL = URL(string:"https://image.tmdb.org/t/p/w500"+actor.profile_path)
        let data = try? Data(contentsOf: photoURL!)
        if let imageData = data {
            cell.imageView?.image = UIImage(data: imageData) //set image of actor cell
        }
        
        //set popularity text
        cell.detailTextLabel?.text = String(actor.popularity)
        
        return cell
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            print("searchText:"+searchText)
            filteredActors = actors.filter { selectedActor in
                return selectedActor.name.lowercased().contains(searchText.lowercased())
            }
            
        } else {
            filteredActors = actors
        }
        tableView.reloadData()
    }
}

