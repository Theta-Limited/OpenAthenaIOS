//
//  DemCacheController.swift
//  OpenAthenaIOS
//
//  Created by Bobby Krupczak on 10/12/23.
//
//  Display our cache of elevation maps in a TableView and allow
//  user to delete or to add new elevation maps/models
//  or view specs on elevation map

import Foundation
import UIKit

class DemCacheController: UIViewController
{
    var demCache: DemCache?
    @IBOutlet var tableView: UITableView!
    var totalStorage: Int = 0 // total storage in bytes
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //view?.backgroundColor = .gray
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // add + button for downloading and adding a new DEM
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        
    } // viewDidLoad
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // reload the cache now rather than first loaded
        // that way, if we navigate back from subsequent view, we'll
        // refresh the list
        demCache = DemCache()
        
        print("DemCacheController view will appear with \(demCache!.count()) entries")
        
        // force table to refresh
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    @objc private func didTapAdd()
    {
        print("Add new elevation map")
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "NewDemController") as! NewDemController
        self.navigationController?.pushViewController(vc, animated: true)
        
    } // didTapAdd
    
    // swipe to delete an entry; try to force confirmation delete button
    // force reload of the table
    
    // delete DEM from app private Documents folder
    private func deleteFile(filename: String, fileURL: URL) -> Bool
    {
        print("Going to delete file \(filename)")
        print("Going to delete url \(fileURL)")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        }
        catch {
            print("Error deleting file \(error)")
            return false
        }
    }
    
} // DemCacheController

extension DemCacheController: UITableViewDelegate, UITableViewDataSource
{
    // default number of sections is 1; make it explicit
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != demCache!.count() {
            print("You tapped \(demCache!.cache[indexPath.row].filename)")
            // switch to DemCacheEntryViewController
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "DemCacheEntryController") as! DemCacheEntryController
            vc.cacheEntry = demCache!.cache[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demCache!.count() + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemCacheTableCell", for: indexPath)
      
        if indexPath.row == demCache!.count() {
            var totalSize: Double = Double(demCache!.totalStorage())
            print("totalSize: \(totalSize), \(totalSize/1024), \(totalSize/1024*1024)")
            var totalSizeStr = "\(totalSize) bytes"
            if totalSize / 1024.0 > 1 {
                totalSize = DemDownloader.truncateDouble(val: totalSize / 1024.0, precision: 1)
                totalSizeStr = "\(totalSize) KB"
            }
            if totalSize / 1024.0 > 1 {
                totalSize = DemDownloader.truncateDouble(val: totalSize / 1024.0, precision: 1)
                totalSizeStr = "\(totalSize) MB"
            }
            
            cell.textLabel?.text = "Total size \(totalSizeStr)"
        }
        else {
            cell.textLabel?.text = demCache!.cache[indexPath.row].filename + "\n"+"Another row of data"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        // don't allow delete of last row which is total storage size
        if indexPath.row == demCache!.count() {
            return .none
        }
        else {
            return .delete
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            tableView.beginUpdates()
            
            let cacheEntry = demCache!.cache[indexPath.row]
            //print("Going to delete \(demCache!.cache[indexPath.row].filename)")
            
            // delete table row
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // delete cache entry and then file itself XXX
            deleteFile(filename: demCache!.cache[indexPath.row].filename,
                       fileURL: demCache!.cache[indexPath.row].fileURL)
            demCache!.removeCacheEntry(index: indexPath.row)
                        
            tableView.endUpdates()
            
            // force reload so that we recalculate/redisplay the total byte count
            DispatchQueue.main.async {
                //print("Reloading tableview")
                self.tableView.reloadData()
            }
        }
        
    } // tableView editingStyle
    
    
 } // exteions for tableview delegate, source

