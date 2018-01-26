/* This ImageJ macro calculates retreives the lifetimes of vesicles in multi(12)phase lifetime images (must be open in ImageJ)
 * It outputs to the result window and the Log window.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 * 
 */


min_size = 3;				//minimum vesicle area in pixels
threshold_motility = 0.3;	//threshold for motile vesicles (set at StdDev/Area^(1/4), in between StdDev and StdErr)


image=getTitle();
name = File.nameWithoutExtension();
run("Colors...", "foreground=white background=black selection=cyan");
if (selectionType>=0 && selectionType<=4) {
	run("Select None");
	run("Duplicate...", "title=temp_for_analysis duplicate");
	run("Restore Selection");
	run("Clear Outside", "stack");
}
else {
	run("Select None");
	run("Duplicate...", "title=temp_for_analysis duplicate");
}
roiManager("Reset");
run("Clear Results");
run("Set Measurements...", "area mean standard redirect=None decimal=3");

setThreshold(-65535, 65535);
run("Analyze Particles...", "size="+min_size+"-500 circularity=0.1-1.00 display clear record add stack");
nr_vesicles = roiManager("Count");
run("Clear Results");
close("temp_for_analysis");
selectWindow(image);
setSlice(1);
run("Select None");

n=0;	//ROIs to delete counter
k=0;	//moving vesicle counter
ROI_indices = newArray(nr_vesicles);
mean_array = newArray(nr_vesicles);
for(i=0;i<nr_vesicles;i++) {
	roiManager("Select",i);
	List.setMeasurements();
	mean = List.getValue("Mean");
//	stdErr = List.getValue("StdDev") / sqrt(List.getValue("Area"));
	stdErr = List.getValue("StdDev") / sqrt(sqrt((List.getValue("Area"))));	//giving some penalty for size, but not that severe
//	stdErr = List.getValue("StdDev");

	if(stdErr < threshold_motility) {
//	if(mean > 2.2 && mean < 3.0) {
		ROI_indices[n]=i;
		n++;
	}
	else {
		setResult("Area", nResults, d2s(List.getValue("Area"),0));
		setResult("Mean", nResults-1, d2s(List.getValue("Mean"),3));
		setResult("StdDev", nResults-1, d2s(List.getValue("StdDev"),3));
		setResult("StdErr", nResults-1, stdErr);
		mean_array[k] = d2s(List.getValue("Mean"),3);
		k++;
	}
}

ROIs_to_delete = Array.trim(ROI_indices, n);	//trim array because it was created too long 
mean_array = Array.trim(mean_array, k);
Array.getStatistics(mean_array, min, max, mean, stdDev);
//print("Deleting "+ROIs_to_delete.length+" vesicles with StdErr < "+threshold_motility);
print("Keeping "+k+" out of "+roiManager("Count")+" detected vesicles, with Error > "+threshold_motility+". Mean: "+mean+" +- "+stdDev);

if(ROIs_to_delete.length>0) {
	roiManager("select", ROIs_to_delete);
	roiManager("Delete");
}
resetThreshold();
run("Select None");
setSlice(1);
roiManager("Show all without labels");
updateDisplay();

dir=getDirectory("image");
roiManager("Save", dir+name+"_ROIs.zip");
