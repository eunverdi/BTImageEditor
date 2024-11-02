//
//  DrawingThicknessPenProtocol.swift
//  BTImageEditor
//
//  Created by Ensar Batuhan Ünverdi on 2.11.2024.
//

import Foundation

protocol DrawingThicknessPenProtocol: AnyObject {
    func showThicknessButtons()
    func hideThicknessButtons()
}

protocol DrawingThicknessPenNavigationDelegate: AnyObject {
    func checkmarkButtonConfigurations()
}
