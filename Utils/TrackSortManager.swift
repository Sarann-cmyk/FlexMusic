//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import Foundation
import CoreData

// Опції сортування для треків
public enum TrackSortOption: String, CaseIterable, Identifiable {
    case title = "Назва"
    case dateAdded = "Дата додавання"
    case artist = "Виконавець"
    case mostPlayed = "Найбільш прослуховувані"
    public var id: String { self.rawValue }
}

public struct TrackSortManager {
    // Сортує масив Song за вибраною опцією
    public static func sort(songs: [Song], by option: TrackSortOption) -> [Song] {
        switch option {
        case .title:
            return songs.sorted { (lhs: Song, rhs: Song) in (lhs.title ?? "") < (rhs.title ?? "") }
        case .dateAdded:
            return songs.sorted { (lhs: Song, rhs: Song) in (lhs.createdAt ?? Date.distantPast) > (rhs.createdAt ?? Date.distantPast) }
        case .artist:
            return songs.sorted { (lhs: Song, rhs: Song) in (lhs.artist ?? "") < (rhs.artist ?? "") }
        case .mostPlayed:
            return songs.sorted { (lhs: Song, rhs: Song) in lhs.playCount > rhs.playCount }
        }
    }
} 
 