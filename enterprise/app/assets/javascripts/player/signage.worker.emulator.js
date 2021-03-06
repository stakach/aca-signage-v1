//= require signage.downloader

function WorkerEmulator(callback) {
	
	// Create an API that looks like postMessage
	this.postMessage = function (data, portArray) {
		downloader.controller(data);	// Clone the data if required JSON.parse(JSON.stringify(message)); // - Don't think it is required
	}
	
	
	this.terminate = function () {
		// No special clean-up needed.
	}
	
	function messageEvtEmulator(rawMessage) {
		callback({ data: rawMessage });
	}
	
	// Create an instance of downloader.
	var downloader = new Downloader(messageEvtEmulator);
}
