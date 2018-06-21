// Developed by: Aissam el Khamsi, Kees jalink, Rolf Harkes, Bram van den Broek
// Year: 2018-06-08

/*
 * Segmentation of cells for lifetime analysis.
 */

 
var step=5;
var max=255;

rename("ORIGINAL");
run("Duplicate...", "title=T");
run("8-bit");
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

selectWindow("ORIGINAL");
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


