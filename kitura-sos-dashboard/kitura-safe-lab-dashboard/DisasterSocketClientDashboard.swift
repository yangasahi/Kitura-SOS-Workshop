//
//  DisasterSocketClient.swift
//  kitura-safe-lab-dashboard
//
//  Created by David Okun on 5/30/19.
//  Copyright © 2019 David Okun. All rights reserved.
//

import Foundation
import Starscream

protocol DisasterSocketClientDashboardDelegate: class {
    func statusReported(client: DisasterSocketClientDashboard, person: Person)
    func clientConnected(client: DisasterSocketClientDashboard)
    func clientDisconnected(client: DisasterSocketClientDashboard)
    func clientErrorOccurred(client: DisasterSocketClientDashboard, error: Error)
    func clientReceivedToken(client: DisasterSocketClientDashboard, token: RegistrationToken)
}

enum DisasterSocketError: Error {
    case badConnection
}

class DisasterSocketClientDashboard {
    
    weak var delegate: DisasterSocketClientDashboardDelegate?
    var address: String
    var id: String?
    public var disasterSocket: WebSocket?
    
    init(address: String) {
        self.address = address
    }
    
    public func attemptConnection() {
        guard let url = URL(string: "ws://\(self.address)/disaster") else {
            delegate?.clientErrorOccurred(client: self, error: DisasterSocketError.badConnection)
            return
        }
        let socket = WebSocket(url: url)
        socket.delegate = self
        disasterSocket = socket
        disasterSocket?.connect()
    }
    
    public func disconnect() {
        disasterSocket?.disconnect()
    }
    
    public func confirm(_ dashboard: Dashboard) {
        self.id = dashboard.dashboardID
        do {
            disasterSocket?.write(data: try JSONEncoder().encode(dashboard))
        } catch let error {
            print("error writing dashboard registration to socket: \(error.localizedDescription)")
        }
    }
    
    public func simulate(_ disaster: Disaster) {
        do {
            try disasterSocket?.write(data: JSONEncoder().encode(disaster))
        } catch let error {
            delegate?.clientErrorOccurred(client: self, error: error)
        }
    }
    
}

extension DisasterSocketClientDashboard: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        delegate?.clientConnected(client: self)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        delegate?.clientDisconnected(client: self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocket message received: \(text)")
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        parse(data)
        print("websocket message received: \(String(describing: String(data: data, encoding: .utf8)))")
    }
    
    private func parse(_ data: Data) {
        
        if let token = try? JSONDecoder().decode(RegistrationToken.self, from: data) {
            print("received registration token: \(token.tokenID)")
            delegate?.clientReceivedToken(client: self, token: token)
        }
        
        if let person = try? JSONDecoder().decode(Person.self, from: data) {
            print("received status of person: \(person.id)")
            delegate?.statusReported(client: self, person: person)
        }
        
    }
}
