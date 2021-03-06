//
//  GovDataRequest.swift
//  
//
//  Created by Michael Pulsifer (U.S. Department of Labor) on 6/18/14.
//  License: Public Domain
//

import Foundation

protocol GovDataRequestProtocol {
    func didCompleteWithError(errorMessage: String)
    func didCompleteWithDictionary(results: NSDictionary)
}

class GovDataRequest {
    
    var delegate: GovDataRequestProtocol? = nil

    var APIKey = ""
    var APIHost = ""
    var APIURL = ""
    var responseFormat = "JSON"
    
    init(APIKey: String, APIHost: String, APIURL:String) {
        self.APIKey = APIKey
        self.APIHost = APIHost
        self.APIURL = APIURL
    }
    
    
    func callAPIMethod (#method: String, arguments: Dictionary<String,String>, timeOut: Double) {
        // Construct the base url based on the provided information
        var url = APIHost + APIURL + "/" + method
        // Start building the query string
        var queryString = ""
        
        // Where appropriate, add the key
        switch APIHost {
        case "http://api.dol.gov":
            queryString = "?KEY=" + APIKey
        case "http://api.census.gov", "http://pillbox.nlm.nih.gov":
            queryString = "?key=" + APIKey
        case "http://api.eia.gov", "http://developer.nrel.gov", "http://api.stlouisfed.org", "http://healthfinder.gov":
            queryString = "?api_key=" + APIKey
        case "http://www.ncdc.noaa.gov":
            queryString = "?token=" + APIKey
        default:
            // do nothing for now
            println("doing nothing for now")
        }
        
        //Construct the arguments part of the query string
        for (argKey, argValue) in arguments {
            switch APIHost {
            case "http://api.dol.gov":
                // DOL's V1 API has specific formatting requirements for arguments in the query string
                switch argKey {
                case "top", "skip", "select", "orderby", "filter":
                    queryString += "&$" + argKey + "=" + argValue
                case "format", "query", "region", "locality", "skipcount":
                    queryString += "&" + argKey + "=" + argValue
                default:
                    println("nothing to see here")
                }
            case "http://go.usa.gov":
                // go.usa.gov requires that the apiKey be the 2nd argument
                if countElements(queryString) == 0 {
                    queryString += "?" + argKey + "=" + argValue + "&apiKey=" + APIKey
                } else {
                    queryString += "&" + argKey + "=" + argValue
                }
            default:
                if countElements(queryString) == 0 {
                    queryString += "?" + argKey + "=" + argValue
                } else {
                    queryString += "&" + argKey + "=" + argValue
                }
            }

        }
        
        //If there are arguments, append them to the url
        if countElements(queryString) > 0 {
            url += queryString
        }
        
        //DOT FMCSA requires that the key be placed at the end.
        if APIHost == "https://mobile.fmcsa.dot.gov" {
            if countElements(queryString) > 0 {
                url += "&webKey=" + APIKey
            } else {
                url += "?webKey=" + APIKey
            }
        }
        
        /*
            ASSUMPTION: data retrieved is in JSON format.
            TODO: consider situation when XML is received.
        */
        
        
        if responseFormat == "JSON" {
            // Send the request to the API and parse the JSON
            var urlToPackage = url.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            println(urlToPackage)
            var urlToSend: NSURL = NSURL(string: urlToPackage)
            var session = NSURLSession.sharedSession()
            var request = NSMutableURLRequest(URL:urlToSend)
            //request.setTimeoutInterval(timeOut)
            request.addValue("application/json",forHTTPHeaderField:"Accept")
            var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
                println("Task completed")
                if(error) {
                    // if there is an error in the request, print it to the console
                    //self.delegate?.didCompleteWithError("Error, Will Robinson")
                    //println(error.localizedDescription)
                    println("oops!")
                }
                var err: NSError?
                var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
                if(err?) {
                    // If there is an error parson JSON, print it to the console
                    NSLog ("Error parsing the JSON")
                }
                self.delegate?.didCompleteWithDictionary(jsonResult)
                })
            task.resume()
        }
    }
    
   
}