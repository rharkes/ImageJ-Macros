debug_mode = true;
n=1;

// code
checkpoint("before filter");
// more code
checkpoint("after filter");
// more code
checkpoint("");
// more code

function checkpoint(message) {
	if(debug_mode==true) {
		setBatchMode("show");	//If you run your macros in Batch mode.
		print("Checkpoint "+n+" reached");
		waitForUser("Checkpoint "+n+": "+message);
		setBatchMode("hide");	//If you run your macros in Batch mode.
		n++;
	}
}
