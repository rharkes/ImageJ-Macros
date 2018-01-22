// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File suffix", value = ".tif") suffix
// @String(label = "Minimum size", value = "400") minsize


/*
 * Macro template to process multiple images in a folder
 */

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

run("Close All");
processFolder(input);
saveAs("Results", output + "\\Results.csv");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	results_merge=""; //variable that will be filled with all results 
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + list[i]))
			processFolder("" + input + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}


function processFile(input, output, file) {
	roiManager("Reset");
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + "\\" + file);
	intfilepath = input + "\\" + file;
	taufilepath = input + "\\" + substring(file,0,lengthOf(file)-5)+"tau.tif";
	outfilepath = output + "\\" + file;
	
	open(intfilepath);
	run("8-bit");
	run("Gaussian Blur...", "sigma=3");
	run("Median...", "radius=7");
//	run("Auto Local Threshold", "method=Niblack radius=15 parameter_1=0 parameter_2=0 white");
	run("Auto Local Threshold", "method=Phansalkar radius=50 parameter_1=0 parameter_2=0");
	run("Watershed");
	run("Analyze Particles...", "size="+minsize+"-Infinity circularity=0.25-1.00 exclude add");
	close();
	open(intfilepath);
	//update ROI's with threshold
	n = roiManager("count"); 
	print("found " + n + " ROIs");
	run("Set Measurements...", "area mean standard min perimeter shape feret's integrated display redirect=None decimal=3");
	 for (i = 0 ; i<n ; i++) { //i++ betekent i=i+1
	 	roiManager("Select", 0); //we remove this roi in the end
	 	run("Measure");
	 	mean=getResult("Mean");
	 	stdv=getResult("StdDev");
	 	IJ.deleteRows(nResults-1, nResults-1); //delete from the resultstable
	 	thresh = mean+3*stdv;
	 	setThreshold(0, thresh);
	 	run("Create Selection");
	 	roiManager("Add"); //all pixels below thresh are in this roi
	 	roiManager("Select", newArray(0,n)); //select new roi and old roi
	 	roiManager("AND"); //below threshold and in cell
	 	roiManager("Add"); //new roi
	 	roiManager("Delete"); //old roi and threshold roi
	 }
	 
	 run("Enhance Contrast", "saturated=0.35");
	 for (i = 0 ; i<n ; i++) { //i++ betekent i=i+1
	 	run("From ROI Manager");
	 } //overlay rois, zorgt er gelijk voor dat het programma niet stopt als er geen Rois gevonden worden.
	 saveAs("Tiff",outfilepath);
	 close();
	
	open(taufilepath);
	roiManager("Show None");
	roiManager("Show All");
	roiManager("Measure");
	close();
}
