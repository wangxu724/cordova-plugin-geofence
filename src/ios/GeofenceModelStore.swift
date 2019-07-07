//
//  GeofenceModelStore.swift
//
//  Created by XuWang on 7/9/19.
//

import Foundation

// TODO: pass errors to cordova application
class GeofenceModelStore {
    init() {
        createDBStructure()
    }

    func createDBStructure() {
        let (tables, err) = SD.existingTables()

        if (err != nil) {
            log(message: "Cannot fetch sqlite tables: \(String(describing: err))")
            return
        }

        if (tables.filter { $0 == "GeofenceModels" }.count == 0) {
            if let err = SD.executeChange(sqlStr: "CREATE TABLE GeofenceModels (ID TEXT PRIMARY KEY, Data TEXT)") {
                //there was an error during this function, handle it here
                log(message: "Error while creating GeofenceModels table: \(err)")
            } else {
                //no error, the table was created successfully
                log(message: "GeofenceModels table was created successfully")
            }
        }
    }

    func addOrUpdate(geofenceModel: JSON) {
        if (findById(id: geofenceModel["id"].stringValue) != nil) {
            update(geofenceModel: geofenceModel)
        }
        else {
            add(geofenceModel: geofenceModel)
        }
    }

    func add(geofenceModel: JSON) {
        let id = geofenceModel["id"].stringValue
        let err = SD.executeChange(sqlStr: "INSERT INTO GeofenceModels (Id, Data) VALUES(?, ?)",
                                   withArgs: [id as AnyObject, geofenceModel.description as AnyObject])

        if err != nil {
            log(message: "Error while adding \(id) GeofenceModel: \(String(describing: err))")
        }
    }

    func update(geofenceModel: JSON) {
        let id = geofenceModel["id"].stringValue
        let err = SD.executeChange(sqlStr: "UPDATE GeofenceModels SET Data = ? WHERE Id = ?",
                                   withArgs: [geofenceModel.description as AnyObject, id as AnyObject])

        if err != nil {
            log(message: "Error while adding \(id) GeofenceModel: \(String(describing: err))")
        }
    }

    func findById(id: String) -> JSON? {
        let (resultSet, err) = SD.executeQuery(sqlStr: "SELECT * FROM GeofenceModels WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            //there was an error during the query, handle it here
            log(message: "Error while fetching \(id) GeofenceModel table: \(String(describing: err))")
            return nil
        } else {
            if (resultSet.count > 0) {
                let jsonString = resultSet[0]["Data"]!.asString()!
                return try? JSON(data: jsonString.data(using: String.Encoding.utf8)!)
            }
            else {
                return nil
            }
        }
    }

    func getAll() -> [JSON]? {
        let (resultSet, err) = SD.executeQuery(sqlStr: "SELECT * FROM GeofenceModels")

        if err != nil {
            //there was an error during the query, handle it here
            log(message: "Error while fetching from GeofenceModels table: \(String(describing: err))")
            return nil
        } else {
            var results = [JSON]()
            for row in resultSet {
                if let data = row["Data"]?.asString() {
                    try? results.append(JSON(data: data.data(using: String.Encoding.utf8)!))
                }
            }
            return results
        }
    }

    func remove(id: String) {
        let err = SD.executeChange(sqlStr: "DELETE FROM GeofenceModels WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            log(message: "Error while removing \(id) GeofenceModel: \(String(describing: err))")
        }
    }

    func clear() {
        let err = SD.executeChange(sqlStr: "DELETE FROM GeofenceModels")

        if err != nil {
            log(message: "Error while deleting all from GeofenceModels: \(String(describing: err))")
        }
    }
}
