//
//  CategoriesTVC.swift
//  HW29CoreData
//
//  Created by Вадим Игнатенко on 26.10.23.
//

import CoreData
import UIKit

final class CategoriesTVC: UITableViewController {
    
    private var category: [CategoryModel] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getData()
    }
    
    @IBAction private func addAction() {
        let alert = UIAlertController(title: "Add new category", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Category name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let tf = alert.textFields?.first,
                  let text = tf.text,
                  text != "",
                  let self else { return }
            let newCategory = CategoryModel(context: self.context)
            newCategory.name = text
            self.category.append(newCategory)
            self.tableView.insertRows(at: [IndexPath(row: self.category.count - 1, section: 0)], with: .fade)
        }))
        self.present(alert, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        category.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let category = category[indexPath.row]
        cell.textLabel?.text = category.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete,
           let name = category[indexPath.row].name
        {
            let request: NSFetchRequest<CategoryModel> = CategoryModel.fetchRequest()
            request.predicate = NSPredicate(format: "name MATCHES %@", name)
            if let categories = try? context.fetch(request) {
                for catigory in categories {
                    context.delete(catigory)
                }
                category.remove(at: indexPath.row)
                saveCategory()
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "ToDoListTVC") as? ToDoListTVC else { return }
        vc.category = category[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }

    private func getData() {
        loadCategories()
        tableView.reloadData()
    }
    
    private func loadCategories(request: NSFetchRequest<CategoryModel> = CategoryModel.fetchRequest()) {
        do {
            category = try context.fetch(request)
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    private func saveCategory() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
