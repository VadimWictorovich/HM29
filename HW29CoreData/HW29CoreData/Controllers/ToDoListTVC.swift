//
//  ToDoListTVC.swift
//  HW29CoreData
//
//  Created by Вадим Игнатенко on 26.10.23.
//

import CoreData
import UIKit

final class ToDoListTVC: UITableViewController {
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private var items: [ItemModel] = []
    var category: CategoryModel? {
        didSet {
            self.title = category?.name
            getData()
        }
    }

    @IBAction private func addItems() {
        let alert = UIAlertController(title: "Add new item", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Item name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let tf = alert.textFields?.first,
                  let text = tf.text,
                  text != "",
                  let self else { return }
            let newItem = ItemModel(context: self.context)
            newItem.title = text
            newItem.done = false
            newItem.parentCategory = self.category
            self.items.append(newItem)
            self.saveItem()
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: .fade)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete,
           let titleName = items[indexPath.row].title
        {
            let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
            request.predicate = NSPredicate(format: "title MATCHES %@", titleName)
            if let titles = try? context.fetch(request) {
                for title in titles {
                    context.delete(title)
                }
                items.remove(at: indexPath.row)
                saveItem()
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].done.toggle()
        self.saveItem()
        tableView.reloadRows(at: [indexPath], with: .fade)
    }

    private func getData() {
        loadItems()
    }

    private func loadItems(request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest(), predicate: NSPredicate? = nil) {
        guard let name = category?.name else { return }
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
        if let predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        do {
            items = try context.fetch(request)
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        tableView.reloadData()
    }

    private func saveItem() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

extension ToDoListTVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            loadItems()
            searchBar.resignFirstResponder()
        } else {
            let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
            let searchPredicate = NSPredicate(format: "title CONTAINS %@", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            loadItems(request: request, predicate: searchPredicate)
        }
    }
}
