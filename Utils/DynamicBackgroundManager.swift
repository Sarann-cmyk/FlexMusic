//
//  ContentView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.04.2025.
//



import SwiftUI
import UIKit

class DynamicBackgroundManager: ObservableObject {
    static let shared = DynamicBackgroundManager()
    
    @Published var backgroundGradient: [Color] = [Color(.systemBackground), Color(.systemBackground)]
    @AppStorage("isDynamicBackgroundEnabled") var isDynamicBackgroundEnabled = false
    
    private init() {}
    
    func updateBackground(from coverData: Data?) {
        guard isDynamicBackgroundEnabled,
              let coverData = coverData,
              let uiImage = UIImage(data: coverData),
              let baseColor = uiImage.averageColor() else {
            // Змінюємо фон з анімацією
            withAnimation(.easeInOut(duration: 1.0)) {
                backgroundGradient = [Color(.systemBackground), Color(.systemBackground)]
            }
            // Миттєво оновлюємо кольори кнопок
            objectWillChange.send()
            return
        }

        // Більш плавні переходи кольорів
        let mainColor = Color(uiColor: baseColor.saturated(amount: 1.2).lightened(by: 0.05))
        let secondColor = Color(uiColor: baseColor.saturated(amount: 0.8).darkened(by: 0.15))
        
        // Зберігаємо поточний колір кнопок перед зміною фону
        let previousButtonColor = controlButtonColor
        
        // Змінюємо фон з анімацією
        withAnimation(.easeInOut(duration: 1.5)) {
            backgroundGradient = [mainColor, secondColor]
        }
        
        // Миттєво оновлюємо кольори кнопок, якщо вони змінилися
        if previousButtonColor != controlButtonColor {
            // Використовуємо withoutAnimation для миттєвої зміни кольорів
            withoutAnimation {
                objectWillChange.send()
            }
        }
    }
    
    // Додаємо новий метод для виконання дій без анімації
    private func withoutAnimation(_ action: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            action()
        }
    }
    
    var controlButtonColor: Color {
        guard isDynamicBackgroundEnabled else {
            return Color(.label)
        }

        // Розрахунок середнього кольору з градієнту
        if let firstColor = backgroundGradient.first,
           let secondColor = backgroundGradient.last {
            
            // Отримуємо UIColor з SwiftUI Color
            let firstUIColor = UIColor(firstColor)
            let secondUIColor = UIColor(secondColor)
            
            var firstRed: CGFloat = 0, firstGreen: CGFloat = 0, firstBlue: CGFloat = 0, firstAlpha: CGFloat = 0
            var secondRed: CGFloat = 0, secondGreen: CGFloat = 0, secondBlue: CGFloat = 0, secondAlpha: CGFloat = 0
            
            firstUIColor.getRed(&firstRed, green: &firstGreen, blue: &firstBlue, alpha: &firstAlpha)
            secondUIColor.getRed(&secondRed, green: &secondGreen, blue: &secondBlue, alpha: &secondAlpha)
            
            // Розрахунок середнього кольору з вагою
            let avgRed = (firstRed * 0.6 + secondRed * 0.4)
            let avgGreen = (firstGreen * 0.6 + secondGreen * 0.4)
            let avgBlue = (firstBlue * 0.6 + secondBlue * 0.4)
            
            // Розрахунок яскравості за формулою: (0.299*R + 0.587*G + 0.114*B)
            let brightness = (0.299 * avgRed + 0.587 * avgGreen + 0.114 * avgBlue)
            
            // На світлому фоні (brightness > 0.65) використовуємо чорний колір
            if brightness > 0.65 {
                return .black
            }
            
            // На темному фоні (brightness ≤ 0.65) використовуємо білий колір
            return .white
        }
        
        return Color(.label)
    }
}

extension UIImage {
    func averageColor() -> UIColor? {
        guard let cgImage = self.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let totalPixels = width * height
        
        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            red += CGFloat(pixelData[offset]) / 255.0
            green += CGFloat(pixelData[offset + 1]) / 255.0
            blue += CGFloat(pixelData[offset + 2]) / 255.0
            alpha += CGFloat(pixelData[offset + 3]) / 255.0
        }
        
        red /= CGFloat(totalPixels)
        green /= CGFloat(totalPixels)
        blue /= CGFloat(totalPixels)
        alpha /= CGFloat(totalPixels)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIColor {
    func brightness() -> CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r * 299 + g * 587 + b * 114) / 1000
    }

    func saturated(amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return UIColor(hue: hue, saturation: min(sat * amount, 1), brightness: bri, alpha: alpha)
    }

    func lightened(by value: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return UIColor(hue: hue, saturation: sat, brightness: min(bri + value, 1), alpha: alpha)
    }

    func darkened(by value: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return UIColor(hue: hue, saturation: sat, brightness: max(bri - value, 0), alpha: alpha)
    }
}

extension Color {
    func uiColor() -> UIColor? {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            let b = CGFloat(hexNumber & 0x0000ff) / 255
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }

        return nil
    }
}
