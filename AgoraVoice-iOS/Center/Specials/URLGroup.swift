//
//  URLGroup.swift
//
//  Created by CavanSu on 2020/3/9.
//  Copyright © 2020 Agora. All rights reserved.
//

import UIKit

struct URLGroup {
    #if PREPRODUCT
    private static let host = "http://api-solutions-pre.sh2.agoralab.co/"
    #elseif PRODUCT
    private static let host = "http://api-solutions.sh2.agoralab.co/"
    #else
    private static let host = "http://api-solutions-dev.bj2.agoralab.co/"
    #endif
    private static let version = "v1/"
    private static let rootPath = "ent/voice/"
    private static var mainPath: String {
        return rootPath + "apps/\(Keys.AgoraAppId)/"
    }
    
    static var userRegister: String {
        return URLGroup.host + URLGroup.mainPath + version + "users"
    }
    
    static var appVersion: String {
        return URLGroup.host + "ent/" + version + "app/version"
    }
    
    static var userLogin: String {
        return URLGroup.host + URLGroup.mainPath + version + "users/login"
    }
    
    static var musicList: String {
        return URLGroup.host + "ent/" + version + "musics"
    }
    
    static var roomPage: String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/page"
    }
    
    static var liveCreate: String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms"
    }
    
    static func liveJoin(roomId: String, userId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/users/\(userId)/join"
    }
    
    static func userUpdateInfo(userId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "users/\(userId)"
    }
    
    static func liveLeave(userId: String, roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/users/\(userId)/leave"
    }
    
    static func liveClose(roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/close"
    }
    
    static func liveSeatStatus(roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/seats"
    }
    
    static func presentGift(roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/gifts"
    }
    
    static func multiHosts(userId: String, roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)/users/\(userId)/seats"
    }
    
    static func roomBackground(roomId: String) -> String {
        return URLGroup.host + URLGroup.mainPath + version + "rooms/\(roomId)"
    }
    
    static func appStore(_ appId: Int) -> String {
        return "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=\(appId)"
    }
}
