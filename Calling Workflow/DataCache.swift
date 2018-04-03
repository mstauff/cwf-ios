//
//  DataCache.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 3/16/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import Foundation

/** An object for storing JSON data on the device filesystem. It consists of an expire time and an [] of JSONObjects. It is an array for flexibility. If you have just a single JSONObject it will just be stored as the single element in the array. If you don't provide an expiration then by default the expiration time is 7 days.*/
struct CacheObject : JSONParsable {
    static public let defaultExpiration = DateComponents( calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: 7, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil )
    
    let expireTime : Date?
    let data : [JSONObject]
    
    /** If there is no expire time then this method will always return false (never expires). Otherwise if it is past the expiration date then it returns true, false otherwise */
    var isExpired : Bool {
        get {
            return expireTime == nil ? false : expireTime! < Date()
        }
    }

    init( withData json : [JSONObject], expiringIn ttl: DateComponents?) {
        data = json
        expireTime = ttl == nil ? nil : Calendar.current.date(byAdding: ttl!, to: Date())
    }

    init( withData json : JSONObject, expiringIn ttl: DateComponents?) {
        self.init(withData: [json], expiringIn: ttl)
    }

    /** Create a cache item with no expiration date. The object will be added into an array so when you retrieve the data you need to reference it as cache.data[0] */
    init( withData json : JSONObject) {
        self.init(withData: [json], expiringIn: nil)
    }

    init( withData json : [JSONObject]) {
        self.init(withData: json, expiringIn: nil)
    }
    
    init?( fromJSON json: JSONObject ) {
        expireTime = Date( fromJSONString: (json[CacheObjectJsonKeys.expireTime] as? String ?? "") )
        data = json[CacheObjectJsonKeys.data] as? [JSONObject] ?? []
        
    }
    
    func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        if let expires = expireTime {
            jsonObj[CacheObjectJsonKeys.expireTime] = expires.jsonDateString() as AnyObject
        }
        jsonObj[CacheObjectJsonKeys.data] = data as AnyObject
        return jsonObj
    }
    
}

private struct CacheObjectJsonKeys {
    static let data = "data"
    static let expireTime = "expireTime"
}

protocol DataCache {
    func store( cacheObject : CacheObject, forKey : String ) -> Bool
    func store( json : JSONObject, forKey : String, expiringIn expireTime : DateComponents ) -> Bool
    func retrieve( forKey : String ) -> CacheObject?

    func storeAsync( cacheObject : CacheObject, forKey : String, completionHandler : @escaping (Bool) -> Void )
    func storeAsync( json : JSONObject, forKey : String, expiringIn expireTime : DateComponents, completionHandler : @escaping (Bool) -> Void )
    func retrieveAsync( forKey : String, completionHandler : @escaping(CacheObject?) -> Void )

}

/** A Cache for storing data on the device file system. Storing and retrieving data should not be done in the UI thread, so there are storeAsync & retrieveAsync methods that use completionHandler's to return results for calling from the main thread. Currently this is used only for storing member class assignments, which we already are running on a background thread because there are network calls involved. So there are also traditional synchronous store/retrieve methods.  */
class FileDataCache : DataCache {
    let cacheFolderUrl : URL?
    let cacheFileExt = ".json"
    
    init( storageLocationUrl : URL? ) {
        if let url = storageLocationUrl {
            cacheFolderUrl = url
        } else {
            // this is going to be in /data/Containers/Data/Application/<App ID>/Library/Caches
            cacheFolderUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
    }
    
    /** Convenience method for storing a single JSONObject in cache. The data will be placed in a CacheObject with the given expiration before being stored in the cache */
    func store(json: JSONObject, forKey: String, expiringIn expireTime: DateComponents) -> Bool {
        let cacheData = CacheObject(withData: json, expiringIn: expireTime)
        return self.store(cacheObject: cacheData, forKey: forKey)
    }
    
    func store(cacheObject: CacheObject, forKey: String) -> Bool {
        var success = false
        if let cacheFolder = cacheFolderUrl {
            // add the key name to the folder path & .json as the file extension
            let cacheFileUrl = cacheFolder.appendingPathComponent( forKey + cacheFileExt)
            if let stream = OutputStream(url: cacheFileUrl, append: false) {
                // todo - document potential need for OperationQueue() if we need greater thread safety
                stream.open()
                JSONSerialization.writeJSONObject(cacheObject.toJSONObject(), to: stream, options: [.prettyPrinted], error: nil)
                stream.close()
                print( "Wrote file: " + cacheFileUrl.absoluteString )
                success = true
            }
        }
        return success
    }

    func storeAsync(cacheObject: CacheObject, forKey: String, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let result = self.store(cacheObject: cacheObject, forKey: forKey)
            completionHandler( result )
        }
    }
    
    func storeAsync(json: JSONObject, forKey: String, expiringIn expireTime: DateComponents, completionHandler: @escaping (Bool) -> Void) {
        let cacheData = CacheObject(withData: json, expiringIn: expireTime)
        storeAsync(cacheObject: cacheData, forKey: forKey, completionHandler: completionHandler )
    }
    
    func retrieveAsync(forKey: String, completionHandler: @escaping (CacheObject?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let result = self.retrieve(forKey: forKey)
            completionHandler( result )
        }
    }
    
    /** Retrieves a CacheObject from the store if it exists. This method always returns the result if it was in the cache. It's up to the caller to check the object to determine if it's expired */
    func retrieve(forKey: String) -> CacheObject? {
        var result : CacheObject? = nil
        if let cacheFolder = cacheFolderUrl {
            let cacheFileUrl = cacheFolder.appendingPathComponent( forKey + cacheFileExt)
            // if the file exists then open an input stream for reading it
            if FileManager.default.fileExists(atPath: cacheFileUrl.path), let stream = InputStream(url: cacheFileUrl) {
                stream.open()
                print( "Reading File " + cacheFileUrl.path)
                if let json = (try? JSONSerialization.jsonObject(with: stream, options: [])) as? JSONObject {
                    result = CacheObject(fromJSON: json)
                }
                stream.close()
            } else {
                print( "File " + cacheFileUrl.path + " not found ")
            }
        }
        return result
    }
    
    
}

protocol DataCacheInjected { }

extension DataCacheInjected {
    var dataCache:DataCache { get { return InjectionMap.dataCache } }
}


