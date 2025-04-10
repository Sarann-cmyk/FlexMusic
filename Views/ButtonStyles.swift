//
//  ButtonStyles.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 19.03.2025.
//

import SwiftUI

/// Основний стиль кнопки для застосування в усьому додатку
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor(isPressed: configuration.isPressed))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func textColor(isPressed: Bool) -> Color {
        if colorScheme == .dark {
            return .white
        } else {
            // У світлій темі використовуємо чорний з меншою насиченістю
            return Color.black.opacity(isPressed ? 0.7 : 0.65)
        }
    }
}

/// Стиль іконок з більш м'яким контрастом
struct IconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var color: Color? = nil
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(color ?? textColor(isPressed: configuration.isPressed))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func textColor(isPressed: Bool) -> Color {
        if colorScheme == .dark {
            return .white
        } else {
            // У світлій темі використовуємо чорний з меншою насиченістю
            return Color.black.opacity(isPressed ? 0.7 : 0.65)
        }
    }
}

/// Розширення для зручного застосування стилів
extension View {
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func iconButtonStyle(color: Color? = nil) -> some View {
        self.buttonStyle(IconButtonStyle(color: color))
    }
} 