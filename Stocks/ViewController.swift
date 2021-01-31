//
//  ViewController.swift
//  Stocks
//
//  Created by Егор Савковский on 30.01.2021.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate {

    // MARK: - UI
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyIconImage: UIImageView!
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        companyPickerView.dataSource = self;
        companyPickerView.delegate = self;
        
        activityIndicator.hidesWhenStopped = true
        
        requestQuoteUpdate()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
    
    // MARK: - Private
    
    private lazy var commpanies = [
        "Apple": "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook": "FB",
        "Novavax, Inc.": "NVAX",
        "Koss Corp.": "KOSS"
    ]
    
    // MARK: - Quote processing
    
    private func requestQuote(for symbol: String) {
        let token = "pk_eda69de6d62b4617b246a659033cb227"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }

        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.parseQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else { return print("Invalid JSON") }
            
                
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            print("JSON paring error: " + error.localizedDescription)
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        companyNameLabel.textColor = UIColor.black
        companyNameLabel.text = "-"
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(commpanies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        requestCompanyImage(symbol: selectedSymbol)
    }
    
    // MARK: - Display info
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        updatePriceColor(priceChange: priceChange)
    }

    private func updatePriceColor(priceChange: Double) {
        if (priceChange > 0) {
            priceChangeLabel.textColor = UIColor.green
        }
        else if (priceChange < 0) {
            priceChangeLabel.textColor = UIColor.red
        }
        else {
            priceChangeLabel.textColor = UIColor.black
        }
    }
    
    // MARK: - Company image processing
    
    private func requestCompanyImage(symbol: String) {
        let token = "pk_eda69de6d62b4617b246a659033cb227"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.parseImage(from: data)
            } else {
                print("Network error!")
            }
        }
        
        dataTask.resume()
    }
    
    private func parseImage(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let imgUrl = json["url"] as? String else { return print("Invalid JSON") }
            
                
            DispatchQueue.main.async { [weak self] in
                self?.setCompanyIconImage(url: imgUrl)
            }
        } catch {
            print("JSON paring error: " + error.localizedDescription)
        }
    }
    
    private func setCompanyIconImage(url: String) {
        let imgUrl = NSURL(string: url)
        if let data = NSData(contentsOf: imgUrl! as URL) {
            companyIconImage.image = UIImage(data: data as Data)
        }
    }
}

// MARK: - UIPickerViewDataSource

extension ViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return commpanies.keys.count
    }
}

// MARK: - UIPickerViewDelegate

extension ViewController: UIDocumentPickerDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(commpanies.keys)[row]
    }
}
