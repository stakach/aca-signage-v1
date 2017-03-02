//= require signage.constants
//= require signage.downloader



var downloader = new Downloader(postMessage);	// Accepts the callback as the parameter



// Hook-up worker input
onmessage = function (e) {
	downloader.controller(e.data);
	
	if (e.data.code == SIG.shutdown)
		close();	// Close the worker.
}
