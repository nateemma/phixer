//
//  Database.swift
//  phixer
//
//  Created by Philip Price on 5/17/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import CoreData
import UIKit


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
    fileprivate static var userChangesEntity: NSEntityDescription? = nil

    
    // Table names
    fileprivate static let settingsName = "SettingsEntity"
    fileprivate static let categoryName = "CategoryEntity"
    fileprivate static let filterName = "FilterEntity"
    fileprivate static let lookupFilterName = "LookupFilterEntity"
    fileprivate static let assignmentName = "AssignmentEntity"
    fileprivate static let presetName = "PresetEntity"
    fileprivate static let userChangesName = "UserChangesEntity"
    
    
    ///////////////////////////////////
    // MARK: - UTILITIES
    ///////////////////////////////////
    
    
    public static func save(){
        
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
    // MARK: - CREATION/DELETION
    ///////////////////////////////////
    

    fileprivate static func deleteDatabase(){
        
    }
    
    fileprivate static func setupDatabase(){
        
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
                //filterEntity = NSEntityDescription.entity(forEntityName: filterName, in: context!)!
                //lookupFilterEntity = NSEntityDescription.entity(forEntityName: lookupFilterName, in: context!)!
                assignmentEntity = NSEntityDescription.entity(forEntityName: assignmentName, in: context!)!
                userChangesEntity = NSEntityDescription.entity(forEntityName: userChangesName, in: context!)!
                //presetEntity = NSEntityDescription.entity(forEntityName: presetName, in: context)!

            } else {
                print("Database.checkDatabase() - ERR: NIL context returned for Database")
            }
        }
    }
    
    // checks to see whether the database has already been set up (and populated)
    public static func isSetup() -> Bool {
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
   
    // identifier used to retrieve settings
    private static let settingsKey = "settings" // just to make it unique rather than a list
    
    // Creates a SettingsEntity (managed) object
    public static func createSettings () -> SettingsEntity? {
        
        return SettingsEntity.init(entity: NSEntityDescription.entity(forEntityName: settingsName, in:context!)!,
                                   insertInto: context!)

    }
    
    
    // Retrieves the current settings. returns nil if nothing has been set yet
    public static func getSettings () -> SettingsRecord? {
        var settings: [SettingsEntity] = []
        var settingsEntity:SettingsEntity? = nil
        var settingsRecord: SettingsRecord
        
        checkDatabase()
        
        settingsEntity = nil
        settingsRecord = SettingsRecord()
        
        let fetchRequest = NSFetchRequest<SettingsEntity>(entityName: settingsName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", settingsKey)
        do {
            settings = try (context?.fetch(fetchRequest))!
            if (settings.count>0){
                if (settings.count>1){
                    log.error("WARNING: found multiple (\(settings.count)) settings")
                }
                settingsEntity = settings[0]
                settingsRecord.key = settingsEntity?.key
                settingsRecord.blendImage = settingsEntity?.blendImage
                settingsRecord.editImage = settingsEntity?.editImage
                settingsRecord.sampleImage = settingsEntity?.sampleImage
                settingsRecord.configVersion = settingsEntity?.configVersion
           } else {
                // build default settings
                settingsRecord.key = settingsKey
                settingsRecord.blendImage = ImageManager.getDefaultBlendImageName()
                settingsRecord.editImage = ImageManager.getDefaultEditImageName()
                settingsRecord.sampleImage = ImageManager.getDefaultSampleImageName()
                settingsRecord.configVersion = "2.0"
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
        

        print("getSettings() - key:\(settingsRecord.key) Sample:\(settingsRecord.sampleImage!) Blend:\(settingsRecord.blendImage!) Edit:\(settingsRecord.editImage!)")
        
        return settingsRecord
    }
    
    
    // saves the supplied Settings to persistent storage
    public static func saveSettings(_ settings: SettingsRecord){
        
        checkDatabase()
        
        var settingList: [SettingsEntity] = []
        var settingsEntity: SettingsEntity? = nil
        
        // get the settings record, creating if necessary
        settingsEntity = nil
        
        let fetchRequest = NSFetchRequest<SettingsEntity>(entityName: settingsName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", settingsKey)
        do {
            settingList = try (context?.fetch(fetchRequest))!
            if (settingList.count>0){
                if (settingList.count>1){
                    print("saveSettings() - ERR: \(settingList.count) Settings records found")
                }
                print("Found exisiting record")
                settingsEntity = settingList[0]
            } else {
                print("Creating new record")
                settingsEntity = createSettings()
            }
        } catch let error as NSError {
            print("saveSettings() - ERR: Could not fetch. \(error), \(error.userInfo)")
        }
        
        if (settingsEntity == nil){
            print("saveSettings() - ERR: no settings table entry found")
        } else {
            
            // update the values based on the settings supplied as argument
            if (settings.key == nil ) { settings.key = settingsKey }
            if ((settings.key?.isEmpty)! ) { settings.key = settingsKey }
            settingsEntity?.update(record:settings)
            print("saveSettings() - Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
            
            save()
        }
        
    }
    
    
    // clears all entries in Settings recoed
    public static func clearSettings(){
        
        print("Database.clearSettings()")
        checkDatabase()
        
        var settingList: [SettingsEntity] = []
        var settingsEntity: SettingsEntity? = nil
        let settings: SettingsRecord = SettingsRecord()
        
        // get the settings record, creating if necessary
        settingsEntity = nil
        
        let fetchRequest = NSFetchRequest<SettingsEntity>(entityName: settingsName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", settingsKey)
        do {
            settingList = try (context?.fetch(fetchRequest))!
            if (settingList.count>0){
                settingsEntity = settingList[0]
                if (settingsEntity == nil){
                    print("saveSettings() - ERR: no settings table entry found")
                } else {
                    
                    // clear all of the values and save
                    settings.key = settingsKey
                    settings.configVersion = "0.0"
                    settings.sampleImage = ""
                    settings.blendImage = ""
                    settings.editImage = ""

                    settingsEntity?.update(record:settings)
                    print("clearSettings() - Sample:\(settings.sampleImage!) Blend:\(settings.blendImage!) Edit:\(settings.editImage!)")
                    
                    save()
                }
            }
        } catch let error as NSError {
            print("clearSettings() - ERR: Could not fetch. \(error), \(error.userInfo)")
        }
        
        
    }
    
    
    
    
    ///////////////////////////////////
    // MARK: - CATEGORIES
    ///////////////////////////////////
    
    // get the list of category records
    public static func getCategoryRecords() -> [CategoryRecord]{
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
    public static func getCategoryRecord(category: String) -> CategoryRecord?{
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
    public static func addCategoryRecord(_ record: CategoryRecord){
        
        var categoryEntity: CategoryEntity?
        
        categoryEntity = NSEntityDescription.insertNewObject(forEntityName: categoryName, into: context!) as? CategoryEntity

        categoryEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing Category record. Data is saved
    public static func updateCategoryRecord(_ record: CategoryRecord){
        
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
    public static func removeCategoryRecord(category: String){
        
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
    
    
    // clear (delete) all category records
    public static func clearCategoryRecords() {

        print("Database.clearCategoryRecords()")
        
        let fetchRequest = NSFetchRequest<CategoryEntity>(entityName: categoryName)
        do {
            let records = try (context?.fetch(fetchRequest))!
            if (records.count>0){
                for rec in records {
                    context?.delete(rec)
                }
            } else {
                print("clearCategoryRecords() NO records found")
            }
        } catch let error as NSError {
            print("clearCategoryRecords() Could not fetch. \(error), \(error.userInfo)")
        }

    }

    

    
    ///////////////////////////////////
    // MARK: - ASSIGNMENTS
    ///////////////////////////////////
    
    
    
    public static func getAssignmentRecords() -> [AssignmentRecord]{
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
    public static func getAssignmentRecord(key: String) -> AssignmentRecord?{
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
    public static func addAssignmentRecord(_ record: AssignmentRecord){
        
        var assignmentEntity: AssignmentEntity?
        
        assignmentEntity = NSEntityDescription.insertNewObject(forEntityName: assignmentName, into: context!) as? AssignmentEntity
        
        assignmentEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing Assignment record. Data is saved
    public static func updateAssignmentRecord(_ record: AssignmentRecord){
        
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
    public static func removeAssignmentRecord(category: String){
        
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
    
    
    // clear (delete) all assignment records
    public static func clearAssignmentRecords() {
        
        print("Database.clearAssignmentRecords()")
        
        let fetchRequest = NSFetchRequest<AssignmentEntity>(entityName: assignmentName)
        do {
            let records = try (context?.fetch(fetchRequest))!
            if (records.count>0){
                for rec in records {
                    context?.delete(rec)
                }
            } else {
                print("clearAssignmentRecords() NO records found")
            }
        } catch let error as NSError {
            print("clearAssignmentRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }

    
    ///////////////////////////////////
    // MARK: - USER CHANGES
    ///////////////////////////////////
    
    // Creates a SettingsEntity (managed) object
    public static func createUserChanges () -> UserChangesEntity? {
        
        return UserChangesEntity.init(entity: NSEntityDescription.entity(forEntityName: userChangesName, in:context!)!,
                                   insertInto: context!)
        
    }
    
    public static func getUserChangesRecords() -> [UserChangesRecord]{
        var userChangesList:[UserChangesRecord]
        
        userChangesList = []
        
        let fetchRequest = NSFetchRequest<UserChangesEntity>(entityName: userChangesName)
        do {
            let userChanges = try (context?.fetch(fetchRequest))!
            if (userChanges.count>0){
                for entity in userChanges {
                    userChangesList.append(entity.toRecord())
                }
            } else {
                print("getUserChangesRecords() NO records found")
            }
        } catch let error as NSError {
            print("getUserChangesRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return userChangesList
    }
    
    
    
    // retrieve a specific UserChanges record
    public static func getUserChangesRecord(key: String) -> UserChangesRecord?{
        var UserChangesRecord: UserChangesRecord?
        
        UserChangesRecord = nil
        
        let fetchRequest = NSFetchRequest<UserChangesEntity>(entityName: userChangesName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        do {
            let userChanges = try (context?.fetch(fetchRequest))!
            if (userChanges.count>0){
                UserChangesRecord = userChanges[0].toRecord()
            } else {
                print("getUserChangesRecords() NO records found")
            }
        } catch let error as NSError {
            print("getUserChangesRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
        return UserChangesRecord
    }
    
    
    // add a new UserChanges entry. Data is saved
    public static func addUserChangesRecord(_ record: UserChangesRecord){
        
        var UserChangesEntity: UserChangesEntity?
        
        UserChangesEntity = NSEntityDescription.insertNewObject(forEntityName: userChangesName, into: context!) as? UserChangesEntity
        
        UserChangesEntity?.update(record: record)
        
        save()
        
    }
    
    
    // update an existing UserChanges record. Data is saved
    public static func updateUserChangesRecord(_ record: UserChangesRecord){
        
        let fetchRequest = NSFetchRequest<UserChangesEntity>(entityName: userChangesName)
        fetchRequest.predicate = NSPredicate(format: "key == %@", record.key!)
        do {
            let userChanges = try (context?.fetch(fetchRequest))!
            if (userChanges.count>0){
                print("updateUserChangesRecord() UPDATE UserChanges: \(record.key) hide:\(record.hide) rating:\(record.rating)")
                userChanges[0].update(record: record)
                save()
            } else {
                print("updateUserChangesRecord() NO record found for: \(record.key). ADDING")
                addUserChangesRecord(record)
            }
        } catch let error as NSError {
            print("updateUserChangesRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    // remove an existing userChanges. Data is saved, i.e. permanent removal
    public static func removeUserChangesRecord(category: String){
        
        let fetchRequest = NSFetchRequest<UserChangesEntity>(entityName: userChangesName)
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        do {
            let userChanges = try (context?.fetch(fetchRequest))!
            if (userChanges.count>0){
                context?.delete(userChanges[0])
                save()
            } else {
                print("updateUserChangesRecord() NO record found for: \(category)")
            }
        } catch let error as NSError {
            print("updateUserChangesRecord() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    
    
    // clear (delete) all user change records
    public static func clearUserChangesRecords() {
        
        print("Database.clearUserChangesRecords()")
        
        let fetchRequest = NSFetchRequest<UserChangesEntity>(entityName: userChangesName)
        do {
            let records = try (context?.fetch(fetchRequest))!
            if (records.count>0){
                for rec in records {
                    context?.delete(rec)
                }
            } else {
                print("clearUserChangesRecords() NO records found")
            }
        } catch let error as NSError {
            print("clearUserChangesRecords() Could not fetch. \(error), \(error.userInfo)")
        }
        
    }

}
