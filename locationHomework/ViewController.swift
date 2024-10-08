//
//  ViewController.swift
//  locationHomework
//
//  Created by eva on 05.10.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: Data

    var annotationDestination: MKPointAnnotation?
    var myRouteOverlay: MKOverlay?
    var locationManager: CLLocationManager
    
    //MARK: Subviews
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.mapType = .hybrid
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        return mapView
    }()
    
    private lazy var buildRouteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Построить маршрут", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 19.0, weight: .bold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.clipsToBounds = false
        button.isHidden = true
        return button
    }()
    
    // MARK: Lifecycle
    
    init () {
        locationManager = CLLocationManager()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    
        setupLocation()
        addSubviews()
        setupConstraints()
        rightBarButtonSetup()
        setupActions()
    }

    // MARK: Private
    
    private func setupActions() {
        buildRouteButton.addTarget(self, action: #selector(pushBuildRouteButton), for: .touchUpInside)
    }
    
    private func setupLocation() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        mapView.addGestureRecognizer(longPress)
        
        locationManager.delegate = self
        mapView.delegate = self
    }
    
    private func addSubviews() {
        view.addSubview(mapView)
        mapView.addSubview(buildRouteButton)
    }
    
    private func setupConstraints() {
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate( [
            mapView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            
            buildRouteButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -30),
            buildRouteButton.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            buildRouteButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            buildRouteButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20)
        ])
    }
    
    private func rightBarButtonSetup() {
        let menuBtn = UIButton(type: .custom)
        menuBtn.frame = CGRect(x: 0.0, y: 0.0, width: 20, height: 20)
        menuBtn.setImage(UIImage(named:"barPointPicker"), for: .normal)
        menuBtn.tintColor = .black
        menuBtn.addTarget(self, action: #selector(gpsPickerButton), for: UIControl.Event.touchUpInside)

        let menuBarItem = UIBarButtonItem(customView: menuBtn)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 18)
        currWidth?.isActive = true
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 24)
        currHeight?.isActive = true
        navigationItem.rightBarButtonItem = menuBarItem
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Сброс", style: .plain, target: self, action: #selector(locationReset))
        
        navigationItem.rightBarButtonItem?.tintColor = .black
        navigationItem.leftBarButtonItem?.tintColor = .black
    }
    
    // MARK: Actions
    
    @objc func locationReset() {
        if annotationDestination != nil {
            mapView.removeAnnotation(annotationDestination!)
            annotationDestination = nil
        }
        
        if myRouteOverlay != nil {
            mapView.removeOverlay(myRouteOverlay!)
            myRouteOverlay = nil
        }
        buildRouteButton.isEnabled = true
    }
    
    @objc func gpsPickerButton() {
        locationManager.requestWhenInUseAuthorization()
        
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            AlertView.alert.show(
                in: self,
                text: "По всей видимости Вы запретили доступ к геолокации!",
                message: "Зайдите в настройки и разрешите доступ."
            )
        }
    }
    
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        if annotationDestination != nil {
            mapView.removeAnnotation(annotationDestination!)
        }
        
        let point = sender.location(in: mapView)
        let location = mapView.convert(point, toCoordinateFrom: mapView)
    
        annotationDestination = MKPointAnnotation()
        annotationDestination?.coordinate = location
        annotationDestination?.title = "Хочу сюда!"
        mapView.addAnnotation(annotationDestination!)
        
        buildRouteButton.isHidden = false
    }
    
    @objc private func pushBuildRouteButton(_ sender: Any) {
        guard let annotationDestination else {
            AlertView.alert.show(
                in: self,
                text: "Вы не задали конечную точку!"
            )
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        if locationManager.authorizationStatus != .authorizedWhenInUse {
            AlertView.alert.show(
                in: self,
                text: "По всей видимости Вы запретили доступ к геолокации!",
                message: "Зайдите в настройки и разрешите доступ."
            )
        }
        
        guard let myCoords = locationManager.location?.coordinate else {
            return
        }
        
        if myRouteOverlay != nil {
            mapView.removeOverlay(myRouteOverlay!)
            myRouteOverlay = nil
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: myCoords))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: annotationDestination.coordinate))

        let direction = MKDirections(request: request)
        
        direction.calculate { [weak self] responce, error in
            guard let self else { return }
            
            if let responce, let route = responce.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coords = locations[0].coordinate
        let region = MKCoordinateRegion(center: coords, latitudinalMeters: 100, longitudinalMeters: 100)
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            myRouteOverlay = overlay
            return renderer
        }
        return MKOverlayRenderer()
    }
}
