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

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list)
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
//	run("Subtract Background...", "rolling=50");
	run("8-bit");
	run("Remove Outliers...", "radius=6 threshold=0 which=Dark");
	run("Median...", "radius=2");
//	run("Auto Local Threshold", "method=Niblack radius=15 parameter_1=0 parameter_2=0 white");
	run("Auto Local Threshold", "method=Mean radius=25 parameter_1=-5 parameter_2=0 white");
	run("Analyze Particles...", "size="+minsize+"-Infinity circularity=0.25-1.00 exclude add");
	close();
	open(intfilepath);
	
	n = roiManager("count"); 
	 if (n > 0) {
	 	run("From ROI Manager"); 
	 } //overlay rois, zorgt er gelijk voor dat het programma niet stopt als er geen Rois gevonden worden.
	 saveAs("Tiff",outfilepath);
	 close();
		

	
	
	open(taufilepath);
	roiManager("Show None");
	roiManager("Show All");
	roiManager("Measure");
	saveAs("Results", output + "\\Results.csv");
	close();
	
}
