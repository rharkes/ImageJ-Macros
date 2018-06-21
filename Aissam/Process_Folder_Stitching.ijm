// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File suffix", value = ".tif") suffix
// @String(label = "Minimum size", value = "400") minsize
// Developed by: Aissam el Khamsi, Kees jalink, Rolf Harkes, Bram van den Broek
// Year: 2018-06-08

/*
 * Segmentation of cells for lifetime analysis.
 */

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

run("Close All");
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	results_merge=""; //variable that will be filled with all results 
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
	print("combined results",String.getResultsHeadings); 
	print("combined results",results_merge); //this table contains all results 
}


function processFile(input, output, file) {
	roiManager("Reset");
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	// file name must be: "stitched_image_XX_Intensity"
	print("Processing: " + input + "\\" + file);
	intfilepath = input + "\\" + file;
	taufilepath = input + "\\" + substring(file,0,lengthOf(file)-13)+"tau.tif";
	outfilepath = output + "\\" + file;
	var step=5;
	var max=255;
	var kjBatch=false;
	
	// Defining Batchname.
	setBatchMode(kjBatch);
	//Open file with intensities.
	open(intfilepath);
		run("8-bit");
		rename("T");
		run("Fire");
		run("Enhance Contrast", "saturated=0.5");
	
	selectWindow("T");
		run("Duplicate...", "title=TT");
		// Enhancing cytoplasm with unsharped mask. Adding a high-pass filtered image and thus sharpens the image.
		run("Unsharp Mask...", "radius=4 mask=0.8");
		run("Smooth", "stack");
		run("Unsharp Mask...", "radius=6 mask=0.8");
		// Subtracting background noise.
		run("Subtract...", "value=0");
		// A kernel is a matrix whose center corresponds to the source pixel and the other elements correspond to neighboring pixels. 
		// The destination pixel is calculated by multiplying each source pixel by its corresponding kernel coefficient and adding the results.
		run("Convolve...", "text1=[-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n-1 -1- 2 -1 -1\n-1 -1 -1 -1 -1\n-1 -1 -1 -1 -1\n] normalize");
		//  This assumes that out-of-image pixels have a value equal to the nearest edge pixel. 
		// This gives higher weight to edge pixels than pixels inside the image, and higher weight to corner pixels than non-corner pixels at the edge.
		run("Gaussian Blur...", "sigma=1");
		run("Duplicate...", "title=First");
		setThreshold(1, 255);
		run("Convert to Mask");
		//masked images is now 1 and 0
		run("Divide...", "value=255"); 

	//for different thresholds, make masks, assign intensity weights and
	//find the maximum so far.
	for(i=12;i<=max;i=i+step){ 
		selectWindow("TT");
		run("Duplicate...", "title=Next");
		setThreshold(i, 255);
		run("Convert to Mask");
		run("Fill Holes");
		//masked image is 1 and 0.
		run("Divide...", "value=255"); 
		//masked image is i and 0.
		run("Multiply...", "value=i"); 
		imageCalculator("Max create", "Next","First");

		//Closing operations.
		selectWindow("First");
		close();
		selectWindow("Result of Next");
		rename("First");
		selectWindow("Next");
		close();
	}
	
	setBatchMode(false); {
		run("Invert LUT");
		run("Fire");

		selectWindow("TT");
		run("Gaussian Blur...", "sigma=4");
		selectWindow("TT");
		run("Min...", "value=0");
		selectWindow("First");
		run("Gaussian Blur...", "sigma=4");
		imageCalculator("Subtract create", "First","TT");
		selectWindow("Result of First");
		//run("Brightness/Contrast...");
		run("Enhance Contrast", "saturated=0.35");
		run("Tile");
		close("T");
		close("TT");
	}

	selectWindow("Result of First");
		run("Unsharp Mask...", "radius=6 mask=0.9");
		run("Unsharp Mask...", "radius=6 mask=0.9");
		run("Subtract...", "value=120");
		run("Auto Local Threshold", "method=Phansalkar radius=50 parameter_1=0.25 parameter_2=0.5");
		// Making the Regions bigger and at the same time, closing holes in order to obtain more circular Region.
		run("Make Binary");
		run("Dilate");
		run("Fill Holes");
		run("Dilate");
		run("Fill Holes");
		// Seperating sticked Regions.
		run("Watershed");
		run("Dilate");
		run("Watershed");
		run("Analyze Particles...", "size=250-4500 circularity=0.60-1.00 show=Outlines add");
		close();
	
	open(intfilepath);
		//update ROI's with threshold.
		n = roiManager("count"); 
		print("found " + n + " ROIs");
		run("Set Measurements...", "area mean standard min perimeter shape display integrated redirect=None decimal=3");
		
		 //i++ betekent i=i+1.
		 for (i = 0 ; i<n ; i++) { 
		 	//we remove this roi in the end.
		 	roiManager("Select", 0); 
		 	run("Measure");
		 	mean=getResult("Mean");
		 	stdv=getResult("StdDev");
		 	//delete from the resultstable.
		 	IJ.deleteRows(nResults-1, nResults-1); 
		 	thresh = mean+100*stdv;
		 	setThreshold(2, thresh);
		 	//all pixels below thresh are in this roi.
		 	roiManager("Add"); 
		 	//select new roi and old roi
		 	roiManager("Select", newArray(0,n)); 
		 	 //below threshold and in cell
		 	roiManager("AND");
		 	//new roi
		 	roiManager("Add");
		 	//old roi and threshold roi 
		 	roiManager("Show All without labels");
	

	 }
		// Creating expand and composite.
		 run("Enhance Contrast", "saturated=0.35");
		 run("Duplicate...", "title=expand");
		 
		 selectWindow("expand");
		 run("Duplicate...", "title=composite");
		 
		 selectWindow("composite");
		 run("8-bit");
		 run("Enhance Contrast", "saturated=0.35");
		 
		 // Thresholding cell islands. Preventing ROIs from showing up outside cell islands.
		 selectWindow("expand");
			 run("8-bit");
			 run("Subtract...", "value=20");
			 run("Auto Threshold", "method=Triangle");
			//run("Threshold...");
			 run("Median...", "radius=5");
			 run("Erode");
			 run("Watershed");
			 run("Convert to Mask");
			 // Inserting nuclei into defined cell islands.  
			 
			 run("Invert LUT");
			 roiManager("Select All");
			 roiManager("Fill");
			 run("Make Binary");
			 run("Invert LUT");
	 	 // Based upon nuclei as center coordinates are drawn with equal distance to nuclei. 
		 run("Voronoi");
		 run("Multiply...", "value=255");
		 run("Duplicate...", "title=expand-2");
		 // Clearing ROI manager.
		 roiManager("Delete");
		 // Creating new ROIs based upon equal distances derived from the center of nuclei.
		 run("Auto Local Threshold", "method=Phansalkar radius=15 parameter_1=0.25 parameter_2=0.5");
		 run("Analyze Particles...", "size=250-1500 circularity=0.60-1.00 add");

	 selectWindow("expand");
	 	 // Using the earlier made composite (Intensity cells) ,and combining this with the new ROIs 
	 	 // based upon center of nuclei.
		 run("Merge Channels...", "c1=expand c2=composite create");
		 selectWindow("Composite");
		 run("Stack to RGB");
		 run("8-bit");
		 run("Enhance Contrast", "saturated=0.35");
		 roiManager("Show All without labels");
		 selectWindow("Composite (RGB)");
		 // Saving the file in outfilepath as a visualization for afterwards.
		 saveAs("Tiff",outfilepath);
		 close();
		 
	//i++ betekent i=i+1 
	//overlay rois, zorgt er gelijk voor dat het programma niet stopt als er geen Rois gevonden worden.
	for (i = 0 ; i<n ; i++) {
	 run("From ROI Manager");
	 } 
		 // The real magic of this macro. Combining lifetime file with cell regions to obtain value per cell.
		 // This is saved afterwards in csv.file.
		open(taufilepath);
			roiManager("Show None");
			roiManager("Show All without labels");
			roiManager("Measure");
			saveAs("Results", output + "\\Results.csv");
			run("Close All");
	}

