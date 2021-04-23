//
//  PersistenceService.swift
//
/*
 * *********************************************************************************************************************
 *
 *  BACKENDLESS.COM CONFIDENTIAL
 *
 *  ********************************************************************************************************************
 *
 *  Copyright 2020 BACKENDLESS.COM. All Rights Reserved.
 *
 *  NOTICE: All information contained herein is, and remains the property of Backendless.com and its suppliers,
 *  if any. The intellectual and technical concepts contained herein are proprietary to Backendless.com and its
 *  suppliers and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret
 *  or copyright law. Dissemination of this information or reproduction of this material is strictly forbidden
 *  unless prior written permission is obtained from Backendless.com.
 *
 *  ********************************************************************************************************************
 */

import Foundation

@objcMembers public class PersistenceService: NSObject {
    
    public func of(_ entityClass: AnyClass) -> DataStoreFactory {
        return DataStoreFactory(entityClass: entityClass)
    }
    
    public func ofTable(_ tableName: String) -> MapDrivenDataStore {
        return MapDrivenDataStore(tableName: tableName)
    }
    
    public func ofView(_ viewName: String) -> MapDrivenDataStore {
        return MapDrivenDataStore(tableName: viewName)
    }
    
    public func describe(tableName: String, responseHandler: (([ObjectProperty]) -> Void)!, errorHandler: ((Fault) -> Void)!) {
        PersistenceServiceUtils(tableName: tableName).describe(responseHandler: responseHandler, errorHandler: errorHandler)
    }
    
    public lazy var permissions: DataPermission = {
        let _permissions = DataPermission()
        return _permissions
    }()
}
