// input tensor [1, 192, 9, 1]
// output tensor [1, 6, 21]
var i = 0
for element in self.inputImages {
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
let probabilities = UnsafeMutableBufferPointer<Float32>.allocate(capacity: 126)
output.data.copyBytes(to: probabilities)