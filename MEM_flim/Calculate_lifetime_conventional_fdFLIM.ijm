/* This ImageJ macro calculates the phase and modulation lifetimes from multi-phase MEM-FLIM images or timelapses.
 * As input it requires:
 * 
 * 1. A 'reference' multipage image file (e.g. .TIF) containing a number of phases (e.g. 12) as frames or slices
 * 2. A 'sample' multipage image file containing a number of phases (e.g. 12) as frames or slices.
 *    Timelapse images should be (one-dimensional) concatenations of such multi-phase images.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 * 
 */



//settings
var freq = 40*pow(10,6);		//Modulation frequency in Hz
var n = 1;						//first harmonic
var nr_phases = 12;
var tau_ref = 3830*pow(10,-12);	//lifetime of the reference in seconds
var begin = 1;					//analyze from frame [begin] to frame [end] with an interval of [step] frames
var end = 999;
var step = 1;

//options
var vesicles = false;			//If true, a Difference-of-Gaussians background subtraction is performed, which is useful when analysing vesicles or foci
var bleach_correction = false;	//A simple bleach correction is applied on timelapse images. Only used to enable creating a mask with a single threshold
var despeckle = true;			//Remove outliers (e.g. hot pixels) with values larger than [outlier_threshold]
var outlier_threshold = 2000;

//Size of the filters for difference of Gaussians filter (only used if vesicles are true)
var sigma_small = 0;
var sigma_large = 4;


var verbose = false;			//if true, batch mode is disabled (mostly used for debugging)

smooth_background = false;
smooth_reference = false;		//Smooth the reference with a Mean filter with [smooth_radius]
smooth_radius = 3;

saveSettings();
if(nImages>0) run("Close All");

reference_path = File.openDialog("Select a reference file.");
sample_path = File.openDialog("Select a sample file.");


//open and preprocess reference file
open(reference_path);
rename("reference");
reference=getTitle();
run("32-bit");
if(smooth_reference==true) run("Mean...", "radius="+smooth_radius+" stack");
getDimensions(width, height, channels, slices, frames);
create_mask(reference, false, false);	//arguments: image_name, boolean(background subtract), boolean(bleach correct)


//open and preprocess sample file
open(sample_path);
dir = getDirectory("image");
file_name=File.nameWithoutExtension;
rename("sample");
sample=getTitle();
run("32-bit");
getDimensions(width, height, channels, slices, frames);

if(frames==1 && slices>frames) run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
getDimensions(width, height, channels, slices, frames);
end=minOf(end,(frames)/nr_phases);	//set to maximum nr. of frames if end is too large


//change into a time series with the phases as z-axis
selectWindow(sample);
if(frames>1) run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="+nr_phases+" frames="+(frames)/nr_phases+" display=Color");
//trim the time series if requested
selectWindow("sample");
run("Make Substack...", "slices=1-"+nr_phases+" frames="+begin+"-"+end);
substack=getTitle();
close(sample);
selectWindow(substack);
rename(sample);
//Create interleaved time series if requested
if(step>1) run("Reduce...", "reduction="+step);
run("Grays");

if (vesicles==true) create_mask(sample, true, bleach_correction);	//arguments: image_name, boolean(background subtract), boolean(bleach correct)
else create_mask(sample, false, bleach_correction);	//arguments: image_name, boolean(background subtract), boolean(bleach correct)

getDimensions(width, height, channels, slices, frames);


if(verbose==false) setBatchMode(true);

//// Retreive REFERENCE phase and modulation using first component Fourier analysis////
selectWindow(reference);
run("Duplicate...", "title=SIN_reference duplicate slices=[] frames=[]");
run("Duplicate...", "title=COS_reference duplicate slices=[] frames=[]");

//F_cos
selectWindow("COS_reference");
//waitForUser("slices: "+slices+", frames:"+frames+", nr_phases:"+nr_phases);
for(phi=0;phi<nr_phases;phi++) {
	Stack.setSlice(phi+1);		//phi=0 starts at frame 1
	run("Multiply...", "value="+cos(2*PI*n*phi/nr_phases));
}
run("Z Project...", "projection=[Sum Slices]");
rename("Fcos_ref");

//F_sin
selectWindow("SIN_reference");
for(phi=0;phi<nr_phases;phi++) {
	Stack.setSlice(phi+1);
	run("Multiply...", "value="+sin(2*PI*n*phi/nr_phases));
}
run("Z Project...", "projection=[Sum Slices]");
rename("Fsin_ref");

//F_DC
selectWindow(reference);
run("Z Project...", "projection=[Sum Slices] all");
rename("F_DC_ref");

//calculate phi_system
imageCalculator("Divide create 32-bit", "Fcos_ref","Fsin_ref");
run("Macro...", "code=v=atan(v)-atan(2*PI*"+freq+"*"+tau_ref+")");	//phi_system + or - phi_reference
rename("Phi_system");
apply_mask(reference,reference,true);

//calculate M_system
selectWindow("Fcos_ref");
run("Square", "stack");
rename("Fcos_ref_squared");
selectWindow("Fsin_ref");
run("Square", "stack");
rename("Fsin_ref_squared");

imageCalculator("Add create 32-bit", "Fsin_ref_squared","Fcos_ref_squared");
rename("Fsin_ref^2 + Fcos_ref^2");
run("Square Root", "stack");
run("Multiply...", "value=2 stack");
rename("2*Sqrt(Fsin_ref^2 + Fcos_ref^2)");
imageCalculator("Divide 32-bit", "2*Sqrt(Fsin_ref^2 + Fcos_ref^2)","F_DC_ref");
rename("M_ref");
run("Macro...", "code=v=v*"+sqrt((pow(2*PI*freq*tau_ref,2)+1))+" stack");
rename("M_system");

//// SAMPLE ////
selectWindow(sample);
run("Duplicate...", "title=SIN_sample duplicate slices=[] frames=[]");
run("Duplicate...", "title=COS_sample duplicate slices=[] frames=[]");



//// Retreive SAMPLE phase and modulation using first component Fourier analysis////
//F_cos
selectWindow("COS_sample");
for(f=1;f<=frames;f++) {
	if(frames>1) Stack.setFrame(f);
	for(phi=0;phi<nr_phases;phi++) {
//		if(frames/nr_phases>1) Stack.setSlice(phi+1);
		Stack.setSlice(phi+1);
		run("Multiply...", "value="+cos(2*PI*n*phi/nr_phases));
	}
}
run("Z Project...", "projection=[Sum Slices] all");
rename("Fcos_sample");

//F_sin
selectWindow("SIN_sample");
for(f=1;f<=frames;f++) {
	if(frames>1) Stack.setFrame(f);
	for(phi=0;phi<nr_phases;phi++) {
		if(frames>1) Stack.setSlice(phi+1);
		Stack.setSlice(phi+1);
		run("Multiply...", "value="+sin(2*PI*n*phi/nr_phases));
	}
}
run("Z Project...", "projection=[Sum Slices] all");
rename("Fsin_sample");

//F_DC
selectWindow(sample);
run("Z Project...", "projection=[Sum Slices] all");
rename("F_DC_sample");

imageCalculator("Divide 32-bit create stack", "Fcos_sample","Fsin_sample");
run("Macro...", "code=v=atan(v) stack");
rename("Phi_sample");
imageCalculator("Subtract create stack", "Phi_sample","Phi_system");
rename("Delta_phi_temp");
run("Duplicate...", "title=Delta_phi duplicate");
//setBatchMode("show");

//calculate phase lifetime
selectWindow("Delta_phi_temp");
run("Macro...", "code=v=(tan(v)/(2*PI*"+freq+"))*1000000000 stack");	//lifetime in nanoseconds
rename("Tau_phase_sample");
//setBatchMode("show");

//calculate M
selectWindow("Fcos_sample");
run("Square", "stack");
rename("Fcos_sample_squared");
selectWindow("Fsin_sample");
run("Square", "stack");
rename("Fsin_sample_squared");

imageCalculator("Add create 32-bit stack", "Fsin_sample_squared","Fcos_sample_squared");
rename("Fsin_sample^2 + Fcos_sample^2");
run("Square Root", "stack");
run("Multiply...", "value=2 stack");
rename("2*Sqrt(Fsin_sample^2 + Fcos_sample^2)");
imageCalculator("Divide 32-bit stack", "2*Sqrt(Fsin_sample^2 + Fcos_sample^2)","F_DC_sample");
rename("M_sample");

imageCalculator("Divide create 32-bit stack", "M_sample","M_system");
rename("M_temp");
setMinAndMax(0,1);
run("Duplicate...", "title=M duplicate");
//setBatchMode("show");

//calculate modulation lifetime
selectWindow("M_temp");
run("Square", "stack");
run("Macro...", "code=v=sqrt(1/v-1)/(2*PI*"+freq+")*1000000000 stack");	//lifetime in nanoseconds
rename("Tau_mod_sample");

apply_mask("M",sample,true);

apply_mask("Delta_phi",sample,true);
apply_mask("Tau_mod_sample",sample,true);
apply_mask("Tau_mod_sample_masked",reference,true);
rename("Tau_mod_sample_masked");
setMinAndMax(1,4);
run("Fire");
setBatchMode("show");
apply_mask("Tau_phase_sample",sample,false);
apply_mask("Tau_phase_sample_masked",reference,false);
tau_phase = getImageID();
setMinAndMax(1,4);
run("Fire");
setBatchMode("show");
if(vesicles==true) saveAs("Tiff", dir+file_name+"_"+nr_phases+"_PHASE_LIFETIME_vesicles");
else saveAs("Tiff", dir+file_name+"_"+nr_phases+"_PHASE_LIFETIME");






function background_subtract(image) { //method: Difference of Gaussians (good for small spots)
	setBatchMode(true);
	showStatus("subtracting background...");
	selectWindow(image);
	run("Duplicate...", "title=large_blur duplicate range=[]");
//	run("Gaussian Blur...", "sigma="+sigma_large+" stack");
//	run("Median...", "radius="+sigma_large+" stack");
	run("Remove Outliers...", "radius="+sigma_large+" threshold=50 which=Bright stack");
	selectWindow(image);
//	run("Duplicate...", "title=small_blur duplicate range=[]");
	rename("small_blur");
	if(sigma_small>0) run("Gaussian Blur...", "sigma="+sigma_small+" stack");
	imageCalculator("Subtract stack", "small_blur", "large_blur");
	close("large_blur");
	selectWindow("small_blur");
	rename(image);
	setBatchMode(false);
	run("Enhance Contrast", "saturated=0.1");
	getMinAndMax(min, max);
	setMinAndMax(0, max);
	showStatus("");
}

function create_mask(image, bgsubtr, bleach_correct) {
	selectWindow(image);
	run("Select None");
//	run("Z Project...", "projection=[Max Intensity] all");	//Do masking on maximum intensity of all phases on first frame. Optionally over all time points.
//	run("Z Project...", "projection=[Max Intensity] all");	//Do masking on maximum intensity of all phases on first frame. Optionally over all time points.
	if(image=="reference") {
		selectWindow(image);
		setSlice(2);
		run("Duplicate...", "title=30");
		selectWindow(image);
		setSlice(8);
		run("Duplicate...", "title=210");
		imageCalculator("Add stack", "30","210");
	}
	else if(vesicles==true) {
		selectWindow(image);
		normalize_stack(image);
		run("Z Project...", "projection=[Max Intensity] all");
	}
	//run("Duplicate...", "title=normalized_image duplicate");
	//run("Enhance Contrast...", "saturated=0.4 normalize process_all");	//Normalize all phases
	else run("Z Project...", "projection=[Average Intensity]");
	rename("create_mask_image");
	run("Grays");
	close("210");
	close("30");
	//close("normalized_image");
	selectWindow("create_mask_image");
	run("16-bit");
	if(bleach_correct==true) {
		run("Bleach Correction", "correction=[Simple Ratio] background=0");
		close("create_mask_image");
		selectWindow("DUP_create_mask_image");
		rename("create_mask_image");
	}

	if (bgsubtr==true) background_subtract("create_mask_image");
//	if (bgsubtr==true && image=="sample") {
//		run("8-bit");
//		run("Auto Local Threshold", "method=Mean radius=4 parameter_1=-50 parameter_2=0 white stack");
//	}
//	else {
		//run("Cyan Hot");
		if(despeckle==true && image!="reference") {
			print("removing outliers >"+outlier_threshold);
			//changeValues(2000,65535,NaN);
			run("Remove Outliers...", "radius=0 threshold="+outlier_threshold+" which=Bright stack");
		}
		run("Threshold...");
		setAutoThreshold("Li dark stack");
		waitForUser("adjust threshold if necessary");
		getThreshold(lower,upper);
		setThreshold(lower,pow(2,bitDepth));
		//run("Convert to Mask", "background=Dark");
		run("Make Binary", "stack");
		run("Invert LUT");
//	}
	if(image!="reference" && vesicles==true) run("Watershed", "stack");
	//run("Options...", "iterations=2 count=2 black pad edm=Overwrite do=Close stack");
	rename("mask_"+image);
	run("Divide...", "value=255 stack");
	//run("Gaussian Blur...", "sigma=1 stack");
	selectWindow(image);
	resetThreshold();
}

function apply_mask(image,mask,keep) { 	//arguments: image name, mask name, retain mask after processing
	selectWindow(image);
	resetThreshold();
	//waitForUser("before "+image+", "+mask);
	imageCalculator("Multiply create 32-bit stack", image,"mask_"+mask);
	//waitForUser("after "+image+", "+mask);
	getDimensions(image_width, image_height, image_channels, image_slices, image_frames);
	for(i=1;i<=image_frames;i++) {
		if(frames>1) Stack.setFrame(i);
		changeValues(0, 0, -10000);
		setThreshold(-9999, 65536);
		run("NaN Background", "slice");
	}
	if(frames/nr_phases>1) Stack.setFrame(1);
	resetThreshold();
	rename(image+"_masked");
	if(keep==false) close("mask_"+mask);
}



//currently not used
function replace_NaN_by_local_mean(image, radius) {
	run("Select None");
	getDimensions(width, height, channels, slices, frames);
	run("Duplicate...", "title="+image+"_NaNs_replaced duplicate");
	image2 = getTitle();
	if(verbose==true) setBatchMode(true);	//always use batch mode
	for(f=1;f<=frames;f++) {
		if(frames/nr_phases>1) Stack.setFrame(f);
		showStatus("replacing NaNs by local mean... frame "+f+"/"+frames);
		for(y=0;y<height;y++) {
		showProgress(y/height);
			for(x=0;x<width;x++) {
				selectWindow(image);
				if(isNaN(getPixel(x,y))==true) {
					makeOval(x-radius, y-radius, radius*2, radius*2);
					getStatistics(area, mean);
					selectWindow(image2);
					setPixel(x,y,mean);
				}
			}
		}
	}
	if(verbose==true) setBatchMode(false);
	selectWindow(image);
	rename(image+"_old");
	selectWindow(image2);
	rename(image);
}

function normalize_stack(image) {
	run("Set Measurements...", "  mean standard median redirect=None decimal=3");
	run("Clear Results");
	setBatchMode(true);
	image = getTitle();
	getDimensions(width, height, channels, slices, frames);
	array = newArray(slices*frames);

	for(f=0;f<frames;f++) {
		Stack.setFrame(f+1);
		for(i=0;i<slices;i++) {
			Stack.setSlice(i+1);
			setAutoThreshold("Li dark");
			run("Measure");
			array[f*slices+i] = getResult("Mean");
			//print(""+f*slices+i+": "+array[i]);
		}
		run("Select None");
		resetThreshold();
	}
		run("Duplicate...", "title=["+image+"_normalized] duplicate");
	
	Array.getStatistics(array, min, max, mean, stdDev);
	for(f=0;f<frames;f++) {
		Stack.setFrame(f+1);
		for(i=0;i<slices;i++) {
			Stack.setSlice(i+1);
		//	print(array[i]);
			run("Multiply...", "value="+mean/array[i]+" slice");
		}
	}
	setBatchMode(false);
}
