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
	setBatchMode(true);						//Run this part in batch mode (no displaying - much faster)
	 for (i = 0 ; i<n ; i++) { //i++ betekent i=i+1
	 	roiManager("Select", i);
		Roi.getBounds(x, y, width, height);	//Get the coordinates of the rectangle surrounding the ROI
		run("Duplicate...", "title=temp");
		selection = getImageID;				//Retreive the ID of the image
		run("Create Mask");
		mask1 = getTitle;
		selectImage(selection);
	 	List.setMeasurements();				//Measure inside the ROI
	 	mean=List.getValue("Mean");
	 	stdv=List.getValue("StdDev");
	 	thresh = mean+3*stdv;
	 	setThreshold(0,thresh);
	 	run("Select None");
	 	run("Create Mask");
	 	mask2 = getTitle;
	 	imageCalculator("AND", mask1,mask2);
		roiManager("Select", i);
		run("Create Selection");
		run("Make Inverse");
	 	setSelectionLocation(x, y);			//Set the location of the new ROI
	 	roiManager("Update"); 				//Update the selected ROI
	 	close();							//close the masks
	 	close();
	 	close();
	 }
	 setBatchMode(false);
	 
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
