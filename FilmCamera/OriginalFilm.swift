import Foundation
struct OriginalFilm: Codable, Identifiable {
    let name: String
    let short: String
    let asset: String
    var id: String {name}
    static let all: [OriginalFilm] = {
        guard let url = Bundle.main.url(forResource:"film-catalog",withExtension:"json"), let data = try? Data(contentsOf:url), let films = try? JSONDecoder().decode([OriginalFilm].self,from:data) else {return []}
        return films
    }()
}

extension FilmPreset {
    static let originals: [FilmPreset] = {
        guard let url = Bundle.main.url(forResource:"original-presets",withExtension:"json"), let data = try? Data(contentsOf:url), let presets = try? JSONDecoder().decode([FilmPreset].self,from:data) else {return []}
        return presets
    }()
}
