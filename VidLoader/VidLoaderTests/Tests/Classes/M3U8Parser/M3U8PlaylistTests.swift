//
//  M3U8PlaylistTests.swift
//  VidLoaderTests
//
//  Created by Petre on 12/10/19.
//  Copyright © 2019 Petre. All rights reserved.
//

import XCTest
@testable import VidLoader

final class M3U8PlaylistTests: XCTestCase {
    private var requestable: MockRequestable!
    private var parser: PlaylistParser!
    
    override func setUp() {
        super.setUp()
        
        requestable = MockRequestable()
        parser = M3U8Playlist(requestable: requestable)
    }
    
    func test_AdjustPlaylistSchemes_WithoutEncryptionKeyInformation_AdjustWillSucceed() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let givenString = "\(SchemeType.original.rawValue)://simple_path"
        let expectedResult: Result<Data, M3U8Error> = .success(.mock(string: givenString))
        var finalResult: Result<Data, M3U8Error>?
        
        // WHEN
        parser.adjust(data: .mock(string: givenString), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
    
    func test_AdjustPlaylistSchemes_WithoutEncryptionKeyKeyword_AdjustWillSucceed() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let givenString = "URI=\"random_url\""
        let expectedResult: Result<Data, M3U8Error> = .success(.mock(string: givenString))
        var finalResult: Result<Data, M3U8Error>?
        
        // WHEN
        parser.adjust(data: .mock(string: givenString), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
    
    func test_AdjustPlaylistSchemes_KeyDownloadFailed_AdjustWillReturnSameResponse() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let givenString = "#EXT-X-KEYURI=\"https://random_url\""
        let givenError: DownloadError = .unknown
        let expectedResult: Result<Data, M3U8Error> = .success(givenString.data!)
        var finalResult: Result<Data, M3U8Error>?
        requestable.dataTaskStub = .mock()
        requestable.completionHandlerStub = (nil, nil, givenError)
        
        // WHEN
        parser.adjust(data: .mock(string: givenString), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
    
    
    func test_AdjustPlaylistSchemes_KeyDownloadSucceeded_AdjustWillSucceed() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let givenString = "#EXT-X-KEYURI=\"https://random_url\""
        let base64String = "Ym9uZF9qYW1lc19ib25k"
        let expectedKey = "#EXT-X-KEYURI=\"\(SchemeType.key.rawValue):\(base64String)\""
        let expectedResult: Result<Data, M3U8Error> = .success(.mock(string: expectedKey))
        var finalResult: Result<Data, M3U8Error>?
        requestable.dataTaskStub = .mock()
        let expectedData = Data(base64Encoded: base64String)
        requestable.completionHandlerStub = (expectedData, HTTPURLResponse.mock(), nil)
        
        // WHEN
        parser.adjust(data: .mock(string: givenString), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
    
    func test_AdjustPlaylistSchemes_RelativePaths_AdjustWillSucceed() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let baseURLString = baseURL.absoluteString
        let givenResponse = "EXT-X-PLAYLIST-TYPE:VOD\n#EXT-X-KEY:random_staff URI=\"relative_random_path\"\n#EXT-X-INDEPENDENT-SEGMENTS\n#EXT-X-MAP:URI=\"audio_english_192_0.mp4\"\n#EXTINF:5.99467,\t\n#EXT-X-BITRATE:194\naudio_english_192_1.mp4\n#EXTINF:5.99467,\n/audio_english_192_2.mp4\n"
        let base64String = "Ym9uZF9qYW1lc19ib25k"
        let expectedResponse = "EXT-X-PLAYLIST-TYPE:VOD\n#EXT-X-KEY:random_staff URI=\"\(SchemeType.key.rawValue):\(base64String)\"\n#EXT-X-INDEPENDENT-SEGMENTS\n#EXT-X-MAP:URI=\"\(baseURLString)/audio_english_192_0.mp4\"\n#EXTINF:5.99467,\t\n#EXT-X-BITRATE:194\n\(baseURLString)/audio_english_192_1.mp4\n#EXTINF:5.99467,\n\(baseURLString)/audio_english_192_2.mp4\n"
        let expectedResult: Result<Data, M3U8Error> = .success(.mock(string: expectedResponse))
        var finalResult: Result<Data, M3U8Error>?
        requestable.dataTaskStub = .mock()
        let expectedData = Data(base64Encoded: base64String)
        requestable.completionHandlerStub = (expectedData, HTTPURLResponse.mock(), nil)
        
        // WHEN
        parser.adjust(data: .mock(string: givenResponse), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
    
    func test_AdjustPlaylistSchemes_RelativePathsWithoutEncryptionKey_AdjustWillSucceed() {
        // GIVEN
        let baseURL = URL.mock(stringURL: "https://base_url")
        let baseURLString = baseURL.absoluteString
        let givenResponse = "#EXTINF:12.012,\n1920_00001.ts\n#EXTINF:12.012,\n1920_00002.ts\n#EXTINF:12.012,\n/1920_00003.ts\n#EXTINF:12.012,\n../1920_00004.ts\n#EXT-X-ENDLIST"
        let base64String = "Ym9uZF9qYW1lc19ib25k"
        let expectedResponse = "#EXTINF:12.012,\n\(baseURLString)/1920_00001.ts\n#EXTINF:12.012,\n\(baseURLString)/1920_00002.ts\n#EXTINF:12.012,\n\(baseURLString)/1920_00003.ts\n#EXTINF:12.012,\n\(baseURLString)/../1920_00004.ts\n#EXT-X-ENDLIST"
        let expectedResult: Result<Data, M3U8Error> = .success(.mock(string: expectedResponse))
        var finalResult: Result<Data, M3U8Error>?
        requestable.dataTaskStub = .mock()
        let expectedData = Data(base64Encoded: base64String)
        requestable.completionHandlerStub = (expectedData, HTTPURLResponse.mock(), nil)
        
        // WHEN
        parser.adjust(data: .mock(string: givenResponse), with: baseURL, completion: { result in
            finalResult = result
        })
        
        // THEN
        XCTAssertEqual(expectedResult, finalResult)
    }
}
