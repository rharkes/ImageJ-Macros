/* This ImageJ macro calculates retreives the siFLIM lifetimes of vesicles in the active lifetime image.
 * It measures in ROIs that are defined by applying the macro 'Measure_vesicles_FD-FLIM' on the corresponding multi(12)phase lifetime image.
 * 
 * It outputs to the result window (vesicle lifetimes and error) and a separate text window (lifetime in individual pixels), and to the Log window.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 * 
 */

min_size = 2;	//minimum amount of non-NaN siFLIM pixels in a multiphase vesicle ROI

getDimensions(width, height, channels, slices, frames);
nr_vesicles = roiManager("Count");
run("Clear Results");
run("Select None");
run("Set Measurements...", "area mean standard redirect=None decimal=3");

k=0;
mean_array = newArray(nr_vesicles);
for(i=0;i<nr_vesicles;i++) {
	roiManager("Select",i);
	run("Measure");
	if(getResult("Area")<min_size) setResult("Mean", nResults-1, NaN);
	//stdErr = getResult("StdDev") / sqrt(getResult("Area"));
	stdErr = getResult("StdDev") / sqrt(sqrt((getResult("Area"))));	//giving some penalty for size, but not that severe
	setResult("Error", nResults-1, stdErr);
	if(!isNaN(getResult("Mean"))) {
		mean_array[k] = getResult("Mean");
		k++;
	}
}
roiManager("Show all without labels");

print("-----------------------------------------");
mean_array = Array.trim(mean_array, k);
Array.getStatistics(mean_array, min, max, mean, stdDev);
print(""+k+"/"+nr_vesicles+" vesicles larger than "+min_size+" pixels. Mean: "+mean+" +- "+stdDev);

//Get all pixel values of the selected vesicles
pixel_array = newArray(width*height);
p=0;	//pixels in vesicles counter
v=0;	//valid vesicles counter

setBatchMode(true);
//Measure pixelwise in vesicles that have at least [min_size] pixels in the siFLIM image
for(i=0;i<nr_vesicles;i++) {	//loop over all vesicles
	showStatus("Measuring vesicle pixel values");
	showProgress(i/nr_vesicles);
	roiManager("select",i);
	//run("Enlarge...", "enlarge=1");
	//roiManager("Update");
	getSelectionBounds(x0, y0, w, h);
	getStatistics(area, mean, min, max, std, histogram);
	if(area>min_size-1) {
		for(y=y0;y<y0+h;y++) {
			for(x=x0;x<x0+w;x++) {
				value = getPixel(x,y);
				if (!isNaN(value)) {
					pixel_array[p]=value;
					p++;
					//setResult("Pixel",p-1,value);
				}
			}
		}
		v++;
	}
}
run("Select None");
setBatchMode(false);

print(""+p+" pixels in "+v+" vesicles");
pixels = Array.trim(pixel_array,p);
Array.show("lifetime in pixels", pixels);

Array.getStatistics(pixels, min, max, mean, stdDev);
print("pixel value statistics: "+mean+" +- "+stdDev);


