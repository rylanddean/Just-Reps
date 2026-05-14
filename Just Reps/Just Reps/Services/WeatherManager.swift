import WeatherKit
import CoreLocation
import Foundation

// Separate NSObject delegate so WeatherManager can be purely @Observable
// without NSObject's KVO interfering with Swift's observation tracking.
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocation: ((CLLocation) -> Void)?
    var onAuthChange: ((CLAuthorizationStatus) -> Void)?

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthChange?(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocation?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

@Observable
final class WeatherManager {
    static let shared = WeatherManager()

    private let service = WeatherService.shared
    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private let locationDelegate = LocationDelegate()

    private(set) var temperatureString: String = "--"
    private(set) var symbolName: String = "thermometer.medium"
    private(set) var conditionText: String = ""
    private(set) var precipitationChance: Int = 0
    private(set) var hasData: Bool = false

    private init() {
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        locationDelegate.onAuthChange = { [weak self] status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self?.locationManager.requestLocation()
            }
        }
        locationDelegate.onLocation = { [weak self] location in
            Task { await self?.fetch(for: location) }
        }
    }

    func requestWeather() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }

    private func fetch(for location: CLLocation) async {
        do {
            let weather = try await service.weather(for: location)
            let current = weather.currentWeather

            let formatter = MeasurementFormatter()
            formatter.unitOptions = .naturalScale
            formatter.numberFormatter.maximumFractionDigits = 0

            temperatureString = formatter.string(from: current.temperature)
            symbolName = current.symbolName
            conditionText = conditionLabel(for: current.condition)

            if let today = weather.dailyForecast.first {
                precipitationChance = Int(today.precipitationChance * 100)
            }
            hasData = true
        } catch {
            #if DEBUG
            print("[WeatherManager] fetch failed: \(error)")
            #endif
        }
    }

    private func conditionLabel(for condition: WeatherCondition) -> String {
        String(describing: condition)
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}
