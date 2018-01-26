var median_radius = 4;
var tolerance = 1000;

//if(nImages>0) run("Close All");

dir = getDirectory("Image");
savedir = dir+"\\results\\"
name = getTitle();

roiManager("Reset");
run("Set Measurements...", "area mean standard redirect=None decimal=3");

setBatchMode(true);

setSlice(1);
run("Duplicate...", "title=Lifetime");
run("Multiply...", "value=1E9 slice");
setMinAndMax(1.5, 4);
run("Fire");
selectWindow(name);
setSlice(2);
run("Duplicate...", "title=Intensity");
run("Enhance Contrast", "saturated=0.35");
run("Duplicate...", "title=Intensity_smoothed");

selectWindow("Intensity_smoothed");
run("Median...", "radius="+median_radius);
run("Find Maxima...", "noise="+tolerance+" output=[Segmented Particles] exclude");
rename("Segmented");
run("Analyze Particles...", "clear add");

close("Segmented");

selectWindow("Intensity_smoothed");
setAutoThreshold("Otsu dark");
run("Create Selection");
resetThreshold();
close("Intensity_smoothed");

selectWindow("Lifetime");
run("Restore Selection");
run("Clear Outside");
run("Select None");
changeValues(0,0,NaN);
roiManager("multi-measure measure_all");

run("Merge Channels...", "c1=Lifetime c2=Intensity create");
selectWindow("Composite");
rename(name+"_analyzed");
roiManager("Show all");
Stack.setDisplayMode("color");

setBatchMode("Exit and display");

saveAs("Tiff", savedir+name+"_analyzed");
selectWindow("Results");
saveAs("Results", savedir+name+"_results.xls");
