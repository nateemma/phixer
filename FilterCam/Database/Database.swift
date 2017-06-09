//
//  Database.swift
//  FilterCam
//
//  Created by Philip Price on 5/17/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData

// Class that encapsulates access to persistent data
// I use CoreData here, since SQLite was proving to be a pain in Swift3

class Database {
    
    // variables for accessing CoreData
    fileprivate static var appDelegate: AppDelegate? = nil
    fileprivate static var context: NSManagedObjectContext? = nil
    
    // Table references
    fileprivate static var settingsEntity: NSEntityDescription? = nil
    fileprivate static var categoryEntity: NSEntityDescription? = nil
    fileprivate static var filterEntity: NSEntityDescription? = nil
    fileprivate static var lookupFilterEntity: NSEntityDescription? = nil
    fileprivate static var assignmentEntity: NSEntityDescription? = nil
    fileprivate static var presetEntity: NSEntityDescription? = nil
    
    
    // Table names
    fileprivate static let settingsName = "SettingsEntity"
    fileprivate static let categoryName = "CategoryEntity"
    fileprivate static let filterName = "FilterEntity"
    fileprivate static let lookupFilterName = "LookupFilterEntity"
    fileprivate static let assignmentName = "AssignmentEntity"
    fileprivate static let presetName = "PresetEntity"
    
    
    ///////////////////////////////////
    // MARK: - UTILITIES
    ///////////////////////////////////
    
    
    open static func save(){
        
        do {
            // Save Managed Object Context
            try context?.save()
            
        } catch {
            print("Unable to save managed object context.")
        }

    }
    
    
    
    // general utility to create a table (entity) in CoreData
    fileprivate static func createRecord(entity: String) -> NSManagedObject? {

        var result: NSManagedObject?
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: entity, in: context!)
        
        if let entityDescription = entityDescription {
            // Create Managed Object
            result = NSManagedObject(entity: entityDescription, insertInto: context)
        }
        
        return result
    }
    
    // general utility to fetch all rows for a table (entity)
    private func fetchRecords(entity: String) -> [NSManagedObject] {
        
        var result = [NSManagedObject]()
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        do {
            // Execute Fetch Request
            let records = try Database.context?.fetch(fetchRequest)
            
            if let records = records as? [NSManagedObject] {
                result = records
            }
            
        } catch {
            print("Database.fetchRecords() Unable to fetch managed objects for entity \(entity).")
        }
        
        return result
    }
    
    
    
    
    ///////////////////////////////////
    // MARK: - CHECKS
    ///////////////////////////////////
    
    // check that global references have been set up
    fileprivate static func checkDatabase(){
        // check to see if global vars have been assigned
        if (appDelegate == nil){
            print ("Database.checkDatabase() - initialising database vars")
            appDelegate = UIApplication.shared.delegate as? AppDelegate
            context = appDelegate?.persistentContainer.viewContext
            
            if (context != nil){
                // set up table references
                settingsEntity = NSEntityDescription.entity(forEntityName: settingsName, in: context!)!
                categoryEntity = NSEntityDescription.entity(forEntityName: categoryName, in: context!)!
                filterEntity = NSEntityDescription.entity(forEntityName: filterName, in: context!)!
                lookupFilterEntity = NSEntityDescription.entity(forEntityName: lookupFilterName, in: context!)!
                assignmentEntity = NSEntityDescription.entity(forEntityName: assignmentName, in: context!)!
                //presetEntity = NSEntityDescription.entity(forEntityName: presetName, in: context)!
            } else {
                print("Database.checkDatabase() - ERR: NIL context returned for Database")
            }
        }
    }
    
    // checks to see whether the database has already been set up (and populated)
    open static func isSetup() -> Bool {
        var setup:Bool = false
        var categories: [CategoryEntity]
        
        checkDatabase()
        
       // we determine whether the database has been populated by the presence of catagories
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        do {
            categories = try (context?.fetch(fetchRequest))!
            setup =  (categories.count>0) ? true : false
        } catch let error as NSError {
            setup = false
            print("Database.isSetup() Could not fetch. \(error), \(error.userInfo)")
        }
        return setup
    }
    
    
    ///////////////////////////////////
    // MARK: - SETTINGS
    ///////////////////////////////////
   
    // Creates a SettingsEntity (managed) object
    open static func createSettings () -> SettingsEntity? {
        
        return SettingsEntity.init(entity: NSEntityDescription.entity(forEntityName: settingsName, in:context!)!,
                                   insertInto: context!)

    }
    
    
    // Retrieves the current settings. returns nil if nothing has been set yet
    open static func getSettings () -> SettingsRecord? {
        var settings: [SettingsEntity] = []
        var settingsEntity:SettingsEntity? = nil
        var settingsRecord: SettingsRecord
        
        checkDatabase()
        
        settingsEntity = nil
        
        let fetchRequest = NSFetchRequest<SettingsEntity>(entityName: settingsName)
        do {
            settings = try (context?.fetch(fetchRequest))!
            if (settings.count>0){
                if (settings.count>1){
                    log.error("WARNING: found multiple (\(settings.count)) settings")
                }
                settingsEntity = settings[0]
            } else {
                // build default settings
                settingsEntity = SettingsEntity()
                settingsEntity?.blendImage = ImageManager.getDefaultBlendImageName()
                settingsEntity?.editImage = ImageManager.getDefaultEditImageName()
                settingsEntity?.sampleImage = ImageManager.getDefaultSampleImageName()
                settingsEntity?.configVersion = "1.0"
                //return nil
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
        
        settingsRecord = SettingsRecord()
        settingsRecord.blendImage = settingsEntity?.blendImage
        settingsRecord.editImage = settingsEntity?.editImage
        settingsRecord.sampleImage = settingsEntity?.sampleImage
        settingsRecord.configVersion = settingsEntity?.configVersion
        print("getSettings() - Sample:\(settingsRecord.sampleImage!) Blend:\(settingsRecord.blendImage!) Edit:\(settingsRecord.editImage!)")
        
        return settingsRecord
    }
    
    
    // saves the supplied Settings to persistent storage
    open static func saveSettings(_ settings: SettingsRecord){
        
        checkDatabase()
        
        var settingList: [SettingsEntity] = []
        var settingsEntity: SettingsEntity? = nil
        
        // get the settings record, creating if necessary
        settingsEntity = nil
        
        let fetchRequest = NSFetchRequest<SettingsEntity>(entityName: settingsName)
        do {
            settingList = try (context?.fetch(fetchRequest))!
            if (settingList.count>0){
                if (settingList.count>1){
                    print("saveSettings() - ERR: \(settingList.count) Settings records found")
                }
                settingsEntity = settingList[0]
            } else {
                settingsEntity = createRecord(entity: settingsName)  as? SettingsEntity
            }
            } catch let error as NSError {
                print("saveSettings() - ERR: Could not fetch. \(error), \(error.userInfo)")
            }
        
        if (settingsEntity == nil){
            print("saveSettings() - ERR: no settings table entry found")
        } else {
            
            // update the values based on the settings supplied as argument
            //settingsEntity?.setValue(settings.configVersion, forKey: "configVersion")
            //settingsEntity?.setValue(settings.blendImage, forKey: "blendImage")
            //settingsEntity?.setValue(settings.sampleImage, forKey: "sampleImage")
            settingsEntity?.update(record:settings)
            print("saveSettings() - Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
            
            save()
        }

    }
    
    
    
    
    ///////////////////////////////////
    // MARK: - CATEGORIES
    ///////////////////////////////////
    
    open static func getCategoryRecords() -> [CategoryRecord]{
        var categoryList:[CategoryRecord]
        
        categoryList = []
 
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        do {
            let categories = try (context?.fetch(fetchRequest))!
            if (categories.count>0){
                for entity in categories {
                    categoryList.append(entity.toRecord())
                }
            } else {
                print("getCategoryRecords() NO records found")
            }
        } catch let error as NSError {
            print("getCategoryRecords() Could not fetch. \(error), \(error.userInfo)")
        }

        return categoryList
    }
    
    
    
    // retrieve a specific category record
    open static func getCategoryRecord(category: String) -> CategoryRecord?{
        var categoryRecord: CategoryRecord?
        
        categoryRecord = nil
        
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", category)
        do {
            let categories = try (context?.fetch(fetchRequest))!
            if (categories.count>0){
                categoryRecord = categories[0].toRecord()
            } else {
                print("getCategoryRecords() NO records found")
            }
        } catch let error as NSError {
            print("getCategoryRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return categoryRecord
    }
    
    
    // add a new Category entry. Data is saved
    open static func addCategoryRecord(_ record: CategoryRecord){
        
        var categoryEntity: CategoryEntity?
        
        categoryEntity = NSEntityDescription.insertNewObject(forEntityName: categoryName, into: context!) as? CategoryEntity

        categoryEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing Category record. Data is saved
    open static func updateCategoryRecord(_ record: CategoryRecord){
        
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", record.key!)
        do {
            let categories = try (context?.fetch(fetchRequest))!
            if (categories.count>0){
                print("updateCategoryRecord() UPDATE Category: \(String(describing: record.key))")
                categories[0].update(record: record)
                save()
            } else {
                print("updateCategoryRecord() NO record found for: \(String(describing: record.key)). ADDING")
                addCategoryRecord(record)
            }
        } catch let error as NSError {
            print("updateCategoryRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // remove an existing Category. Data is saved, i.e. permanent removal
    open static func removeCategoryRecord(category: String){
        
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", category)
        do {
            let categories = try (context?.fetch(fetchRequest))!
            if (categories.count>0){
                context?.delete(categories[0])
                save()
            } else {
                print("updateCategoryRecord() NO record found for: \(category)")
            }
        } catch let error as NSError {
            print("updateCategoryRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // don't need save since records are saved as they are added/updated/deleted
    
    
    ///////////////////////////////////
    // MARK: - FILTERS
    ///////////////////////////////////
    
    open static func getFilterRecords() -> [FilterRecord]{
        var filterList:[FilterRecord]
        
        filterList = []
        
        let fetchRequest = NSFetchRequest<FilterEntity>(entityName: filterName)
        do {
            let filters = try (context?.fetch(fetchRequest))!
            if (filters.count>0){
                for entity in filters {
                    filterList.append(entity.toRecord())
                }
            } else {
                print("getFilterRecords() NO records found")
            }
        } catch let error as NSError {
            print("getFilterRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return filterList
    }
    
    
    
    // retrieve a specific filter record
    open static func getFilterRecord(key: String) -> FilterRecord?{
        var filterRecord: FilterRecord?
        
        filterRecord = nil
        
        let fetchRequest = NSFetchRequest<FilterEntity>(entityName: filterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let filters = try (context?.fetch(fetchRequest))!
            if (filters.count>0){
                filterRecord = filters[0].toRecord()
            } else {
                print("getFilterRecords() NO records found")
            }
        } catch let error as NSError {
            print("getFilterRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return filterRecord
    }
    
    
    // add a new Filter entry. Data is saved
    open static func addFilterRecord(_ record: FilterRecord){
        
        var filterEntity: FilterEntity?
        
        filterEntity = NSEntityDescription.insertNewObject(forEntityName: filterName, into: context!) as? FilterEntity
        
        filterEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing Filter record. Data is saved
    open static func updateFilterRecord(_ record: FilterRecord){
        
        let fetchRequest = NSFetchRequest<FilterEntity>(entityName: filterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", record.key!)
        do {
            let filters = try (context?.fetch(fetchRequest))!
            if (filters.count>0){
                print("updateFilterRecord() UPDATE Filter: \(String(describing: record.key))")
                filters[0].update(record: record)
                save()
            } else {
                print("updateFilterRecord() NO record found for: \(String(describing: record.key)). ADDING")
                addFilterRecord(record)
            }
        } catch let error as NSError {
            print("updateFilterRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // remove an existing Filter. Data is saved, i.e. permanent removal
    open static func removeFilterRecord(key: String){
        
        let fetchRequest = NSFetchRequest<FilterEntity>(entityName: filterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let filters = try (context?.fetch(fetchRequest))!
            if (filters.count>0){
                context?.delete(filters[0])
                save()
            } else {
                print("updateFilterRecord() NO record found for: \(key)")
            }
        } catch let error as NSError {
            print("updateFilterRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // don't need save since records are saved as they are added/updated/deleted
    
    
    ///////////////////////////////////
    // MARK: - LOOKUP FILTERS
    ///////////////////////////////////
    
    
    open static func getLookupLookupFilterRecords() -> [LookupFilterRecord]{
        var lookupList:[LookupFilterRecord]
        
        lookupList = []
        
        let fetchRequest = NSFetchRequest<LookupFilterEntity>(entityName: lookupFilterName)
        do {
            let lookups = try (context?.fetch(fetchRequest))!
            if (lookups.count>0){
                for entity in lookups {
                    lookupList.append(entity.toRecord())
                }
            } else {
                print("getLookupFilterRecords() NO records found")
            }
        } catch let error as NSError {
            print("getLookupFilterRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return lookupList
    }
    
    
    
    // retrieve a specific lookup record
    open static func getLookupFilterRecord(key: String) -> LookupFilterRecord?{
        var lookupRecord: LookupFilterRecord?
        
        lookupRecord = nil
        
        let fetchRequest = NSFetchRequest<LookupFilterEntity>(entityName: lookupFilterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let lookups = try (context?.fetch(fetchRequest))!
            if (lookups.count>0){
                lookupRecord = lookups[0].toRecord()
            } else {
                print("getLookupFilterRecords() NO records found")
            }
        } catch let error as NSError {
            print("getLookupFilterRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return lookupRecord
    }
    
    
    // add a new LookupFilter entry. Data is saved
    open static func addLookupFilterRecord(_ record: LookupFilterRecord){
        
        var lookupEntity: LookupFilterEntity?
        
        lookupEntity = NSEntityDescription.insertNewObject(forEntityName: lookupFilterName, into: context!) as? LookupFilterEntity
        
        lookupEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing LookupFilter record. Data is saved
    open static func updateLookupFilterRecord(_ record: LookupFilterRecord){
        
        let fetchRequest = NSFetchRequest<LookupFilterEntity>(entityName: lookupFilterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", record.key!)
        do {
            let lookups = try (context?.fetch(fetchRequest))!
            if (lookups.count>0){
                print("updateLookupFilterRecord() UPDATE LookupFilter: \(String(describing: record.key))")
                lookups[0].update(record: record)
                save()
            } else {
                print("updateLookupFilterRecord() NO record found for: \(String(describing: record.key)). ADDING")
                addLookupFilterRecord(record)
            }
        } catch let error as NSError {
            print("updateLookupFilterRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // remove an existing LookupFilter. Data is saved, i.e. permanent removal
    open static func removeLookupFilterRecord(key: String){
        
        let fetchRequest = NSFetchRequest<LookupFilterEntity>(entityName: lookupFilterName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let lookups = try (context?.fetch(fetchRequest))!
            if (lookups.count>0){
                context?.delete(lookups[0])
                save()
            } else {
                print("updateLookupFilterRecord() NO record found for: \(key)")
            }
        } catch let error as NSError {
            print("updateLookupFilterRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // don't need save since records are saved as they are added/updated/deleted
    
    
    ///////////////////////////////////
    // MARK: - ASSIGNMENTS
    ///////////////////////////////////
    
    
    
    open static func getAssignmentRecords() -> [AssignmentRecord]{
        var assignmentList:[AssignmentRecord]
        
        assignmentList = []
        
        let fetchRequest = NSFetchRequest<AssignmentEntity>(entityName: assignmentName)
        do {
            let assignments = try (context?.fetch(fetchRequest))!
            if (assignments.count>0){
                for entity in assignments {
                    assignmentList.append(entity.toRecord())
                }
            } else {
                print("getAssignmentRecords() NO records found")
            }
        } catch let error as NSError {
            print("getAssignmentRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return assignmentList
    }
    
    
    
    // retrieve a specific assignment record
    open static func getAssignmentRecord(key: String) -> AssignmentRecord?{
        var assignmentRecord: AssignmentRecord?
        
        assignmentRecord = nil
        
        let fetchRequest = NSFetchRequest<AssignmentEntity>(entityName: assignmentName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let assignments = try (context?.fetch(fetchRequest))!
            if (assignments.count>0){
                assignmentRecord = assignments[0].toRecord()
            } else {
                print("getAssignmentRecords() NO records found")
            }
        } catch let error as NSError {
            print("getAssignmentRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return assignmentRecord
    }
    
    
    // add a new Assignment entry. Data is saved
    open static func addAssignmentRecord(_ record: AssignmentRecord){
        
        var assignmentEntity: AssignmentEntity?
        
        assignmentEntity = NSEntityDescription.insertNewObject(forEntityName: assignmentName, into: context!) as? AssignmentEntity
        
        assignmentEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing Assignment record. Data is saved
    open static func updateAssignmentRecord(_ record: AssignmentRecord){
        
        let fetchRequest = NSFetchRequest<AssignmentEntity>(entityName: assignmentName)
        fetchRequest.predicate = NSPredicate(format: "category == %@", record.category!)
        do {
            let assignments = try (context?.fetch(fetchRequest))!
            if (assignments.count>0){
                print("updateAssignmentRecord() UPDATE Assignment: \(String(describing: record.category)) \(record.filters)")
                assignments[0].update(record: record)
                save()
            } else {
                print("updateAssignmentRecord() NO record found for: \(String(describing: record.category)). ADDING")
                addAssignmentRecord(record)
            }
        } catch let error as NSError {
            print("updateAssignmentRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // remove an existing Assignment. Data is saved, i.e. permanent removal
    open static func removeAssignmentRecord(category: String){
        
        let fetchRequest = NSFetchRequest<AssignmentEntity>(entityName: assignmentName)
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        do {
            let assignments = try (context?.fetch(fetchRequest))!
            if (assignments.count>0){
                context?.delete(assignments[0])
                save()
            } else {
                print("updateAssignmentRecord() NO record found for: \(category)")
            }
        } catch let error as NSError {
            print("updateAssignmentRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    
    ///////////////////////////////////
    // MARK: - PRESETS
    ///////////////////////////////////
    

    //TODO
}
