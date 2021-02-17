//
//  TabViewController.swift
//  SistemiDigitali
//
//  Created by Dario De Nardi on 05/02/21.
//

import UIKit
import Firebase
import TensorFlowLite
import Charts
import TinyConstraints

class TabViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var interpreter: Interpreter!
    var fileName: String = ""
    var inputArray: [[[[Float32]]]] = []
    var tabValues: [ChartDataEntry] = []
    
    lazy var chartView: BubbleChartView = {
       let chartView = BubbleChartView()
        chartView.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        return chartView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("🟢", #function)
        
        self.titleLabel.text = fileName
        
        view.addSubview(chartView)
        chartView.centerInSuperview()
        chartView.width(to: view)
        chartView.heightToWidth(of: view)
        
        chartView.delegate = self
        
        //chartView.setScaleEnabled(true)
        
        chartView.drawGridBackgroundEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.dragEnabled = false
        chartView.xAxis.enabled = false
        chartView.leftAxis.enabled = true
        chartView.rightAxis.enabled = false
        chartView.chartDescription?.enabled = false
        chartView.legend.enabled = false
        
        chartView.leftAxis.labelFont = UIFont(name: "Arlon-Regular", size: 10)!
        
        let array = ["E","A","D","G","B","e"]
        chartView.leftAxis.valueFormatter = IndexAxisValueFormatter(values: array)
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.granularityEnabled = true
        chartView.leftAxis.drawZeroLineEnabled = false
        chartView.leftAxis.labelFont = UIFont.boldSystemFont(ofSize: 12)
        chartView.leftAxis.labelTextColor = .white
        chartView.leftAxis.granularity = 1
        chartView.leftAxis.axisMinimum = 0
        chartView.leftAxis.axisMaximum = 5
        
        chartView.xAxis.axisMinimum = 0
        chartView.xAxis.axisMaximum = Double(self.inputArray.count)
        
        //chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelFont = UIFont.boldSystemFont(ofSize: 12)
        tabValues = []
        do {
            // input tensor [1, 192, 9, 1]
            // output tensor [1, 6, 19]
            var i = 1
            for element in self.inputArray {
                var inputData = Data()
                for element2 in element {
                    for element3 in element2 {
                        for element4 in element3 {
                            var f = Float32(element4)
                            let elementSize = MemoryLayout.size(ofValue: f)
                            var bytes = [UInt8](repeating: 0, count: elementSize)
                            memcpy(&bytes, &f, elementSize)
                            inputData.append(&bytes, count: elementSize)
                        }
                    }
                }
                
                try self.interpreter.allocateTensors()
                try self.interpreter.copy(inputData, toInputAt: 0)
                try self.interpreter.invoke()
                
                let output = try self.interpreter.output(at: 0)
                let probabilities =
                        UnsafeMutableBufferPointer<Float32>.allocate(capacity: 114)
                output.data.copyBytes(to: probabilities)
                
                print("IMG", i)
                var positions: [Int] = []
                
                var maxTempButtonValue: Float32 = 0
                var maxTempButtonPosition = 0
                var z = 0
                for string in 0...5 {
                    //print("CORDA", (y+1))
                    for flat in 0...18 {
                        if (probabilities[z] > maxTempButtonValue) {
                            maxTempButtonValue = probabilities[z]
                            maxTempButtonPosition = flat
                        }
                        //print(probabilities[z])
                        z = z + 1
                    }
                    positions.append(maxTempButtonPosition)
                    
                    // colonna[0]: se suono o no = 1 no suono
                    // colonna[1]: se non suono i tasti ma solo la corda
                    if (maxTempButtonPosition != 0) {
                        tabValues.append(BubbleChartDataEntry(x: Double(i), y: Double(string), size: CGFloat(maxTempButtonPosition)))
                    }
                } // for string
                
                print(positions)
                
                //
                setData()
                i = i + 1
            }
            
        } catch {
            print("Unexpected predictions")
            return
        }
        
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    func setData() {
        let set1 = BubbleChartDataSet(entries: tabValues, label: "")
        set1.drawIconsEnabled = false
        set1.setColor(.white, alpha: 0.0)
        //set1.drawValuesEnabled = true
        set1.valueFormatter = DefaultValueFormatter(decimals: 0)
        
        let data = BubbleChartData(dataSet: set1)
        data.setDrawValues(true)
        data.setValueFont(UIFont(name: "Arlon-Regular", size: 12)!)
        data.setHighlightCircleWidth(0)
        data.setValueTextColor(.white)
        
        chartView.data = data
    }
    
}
