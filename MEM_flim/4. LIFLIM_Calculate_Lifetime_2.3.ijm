/*
 * This macro calculates the phase and modulation lifetimes of Lambert Instruments .FLI files.
 * As input it requires:
 * 1. a reference file (e.g. TIF) with n frames with different phases (typically 12).
 * 2. a .FLI file containing a timelapse
 * 
 * Background subtraction (dark image) should be done proir to this macro.
 * 
 * The polar plot movie of a region is calculated and displayed as mean and standard deviation of the pixels in the region.
 * 
 * Bram van den Broek (b.vd.broek@nki.nl), Netherlands Cancer Institute, 2014-2015
 * 
 * 
 * version 2.3: included bleaching correction
 */



//variables
var freq = 40*pow(10,6);		//frequency in Hz
var n = 1;						//first harmonic
var nr_phases = 12;
var tau_ref = 3830*pow(10,-12);	//lifetime of reference in seconds
var begin = 1;
var end = 999;
var step = 1;

var polar_tau_1 = 1*pow(10,-9);	//lifetime of tau 1 of polar plot help line in seconds
var polar_tau_2 = 4*pow(10,-9);	//lifetime of tau 2 of polar plot help line in seconds

var sigma_small = 0.5;
var sigma_large = 4;

var vesicles = false;			//If true, a Difference-of-Gaussians background subtraction is performed, which is useful when analysing vesicles or foci
var bleach_correction = false;
var despeckle = true;			//Remove outliers (e.g. hot pixels) with values larger than outlier_threshold
var outlier_threshold = 2000;

var verbose = false;

smooth_background = false;
smooth_reference = false;
smooth_mask = false;
smooth_radius = 3;

if(nImages>0) run("Close All");

reference_path = File.openDialog("Select a reference file.");
sample_path = File.openDialog("Select a sample file.");


//open and preprocess reference FLI file
//run("Bio-Formats Importer", "open=["+reference_path+"] autoscale color_mode=Default concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
open(reference_path);
rename("reference");
reference=getTitle();
run("32-bit");
if(smooth_reference==true) run("Mean...", "radius="+smooth_radius+" stack");
getDimensions(width, height, channels, slices, frames);
create_mask(reference, false, false);	//arguments: image_name, boolean(background subtract), boolean(bleach correct)


//open and preprocess sample FLI file
//run("Bio-Formats Importer", "open=["+sample_path+"] autoscale color_mode=Default concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
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

//// REFERENCE ////
selectWindow(reference);
run("Duplicate...", "title=SIN_reference duplicate slices=[] frames=[]");
run("Duplicate...", "title=COS_reference duplicate slices=[] frames=[]");

//Retreive reference phase
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


//Retreive sample phase
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
//setBatchMode("show");

//if(verbose==false) setBatchMode(false);

apply_mask("M",sample,true);
//setBatchMode("show");
//run("Enhance Contrast", "saturated=0.35");

apply_mask("Delta_phi",sample,true);
//setBatchMode("show");
//run("Enhance Contrast", "saturated=0.35");
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
//rename("Tau_phase_sample_masked");
if(vesicles==true) saveAs("Tiff", dir+file_name+"_12_PHASE_LIFETIME_vesicles");
else saveAs("Tiff", dir+file_name+"_12_PHASE_LIFETIME");




next = getBoolean("Create polar plot?");

//next=false;
while(next==true) {

run("Select None");
//setBatchMode(true);
setBatchMode("show");
roiManager("Reset");

//Polar Plot
//setBatchMode(false);
selectWindow("Tau_phase_sample_masked");
run("Select None");
//setBatchMode(true);
setBatchMode("show");
getDimensions(width, height, channels, slices, frames);

//Select region to plot
setTool("freehand");
waitForUser("Select region for Polar Plot or ESC to cancel");
roiManager("Add");
roiManager("Remove Slice Info");
roiManager("Remove Frame Info");


M = newArray(frames);
Phi = newArray(frames);
M_stdev = newArray(frames);
Phi_stdev = newArray(frames);

selectWindow("M_masked");
roiManager("Select",0);
for(i=0;i<frames;i++) {
	if(frames/nr_phases>1) Stack.setFrame(i+1);
		roiManager("Select",0);
		getStatistics(area, mean, min, max, std, histogram);
		M[i]=mean;
		M_stdev[i]=std;
}
selectWindow("Delta_phi_masked");
for(i=0;i<frames;i++) {
	if(frames/nr_phases>1) Stack.setFrame(i+1);
		roiManager("Select",0);
		getStatistics(area, mean, min, max, std, histogram);
		Phi[i]=mean;
		Phi_stdev[i]=std;
}

Polar_x = newArray(frames);
Polar_x_stdev = newArray(frames);
Polar_y = newArray(frames);
Polar_y_stdev = newArray(frames);

showStatus("Calculating polar plot...");
for(i=0;i<Polar_x.length;i++) Polar_x[i] = abs(M[i]*cos(Phi[i]));		//take absolute value: quick fix!
for(i=0;i<Polar_x.length;i++) Polar_x_stdev[i] = sqrt( pow(cos(Phi[i])*M_stdev[i],2) + pow(M[i]*sin(Phi[i])*Phi_stdev[i],2) );
//for(i=0;i<Polar_x.length;i++) print(Polar_x[i]+" +- "+Polar_x_stdev[i]);
for(i=0;i<Polar_y.length;i++) Polar_y[i] = abs(M[i]*sin(Phi[i]));		//take absolute value: quick fix!
for(i=0;i<Polar_y.length;i++) Polar_y_stdev[i] = sqrt( pow(sin(Phi[i])*M_stdev[i],2) + pow(M[i]*cos(Phi[i])*Phi_stdev[i],2) );
//for(i=0;i<Polar_y.length;i++) print(Polar_y[i]+" +- "+Polar_y_stdev[i]);


//The fixed semicircle
Circle_x = newArray(315);
Circle_y = newArray(315);
for(i=0;i<Circle_x.length;i++) {
	Circle_x[i] = 0.5*cos(i/100)+0.5;
	Circle_y[i] = 0.5*sin(i/100);
}

//line from polar_tau_1 to polar_tau_2
delta_phi_polar_1 = atan(2*PI*freq*polar_tau_1);
delta_phi_polar_2 = atan(2*PI*freq*polar_tau_2);
m_polar_1 = sqrt(1/(pow(2*PI*freq*polar_tau_1,2)+1));
m_polar_2 = sqrt(1/(pow(2*PI*freq*polar_tau_2,2)+1));
polar_help_line_x = newArray(2);
polar_help_line_y = newArray(2);
polar_help_line_x[0] = m_polar_1*cos(delta_phi_polar_1);
polar_help_line_x[1] = m_polar_2*cos(delta_phi_polar_2);
polar_help_line_y[0] = m_polar_1*sin(delta_phi_polar_1);
polar_help_line_y[1] = m_polar_2*sin(delta_phi_polar_2);

if(verbose==true) setBatchMode(true);
print("\\Clear");
requires("1.49e");

run("Profile Plot Options...", "width=1000 height=600 interpolate draw sub-pixel");
for(f=1;f<=frames;f++) {
	Plot.create("Plot", "M*Cos(Phi)", "M*Sin(Phi)");
	Plot.setLimits(0, 1, 0, 0.6);
	Polar_x_frame = Array.slice(Polar_x,f-1,f);
	Polar_y_frame = Array.slice(Polar_y,f-1,f);
	Polar_x_stdev_frame = Array.slice(Polar_x_stdev,f-1,f);
	Polar_y_stdev_frame = Array.slice(Polar_y_stdev,f-1,f);

	//the data with error bars
	Plot.setLineWidth(1);
	Plot.setColor("blue");
	Plot.add("circles", Polar_x_frame, Polar_y_frame);
	Plot.setLineWidth(2);
	Plot.setColor("Gray");
	Plot.add("xerrors", Polar_x_stdev_frame);
	Plot.add("yerrors", Polar_y_stdev_frame);
	Plot.setLineWidth(2);
	Plot.setColor("#8888ff");
	Plot.add("line", Polar_x, Polar_y);
	Plot.setLineWidth(4);
	Plot.setColor("blue");
	Plot.add("circles", Polar_x_frame, Polar_y_frame);	//replot to get the data on top

	//the semicircle and help line
	Plot.setLineWidth(1);
	Plot.setColor("black");
	Plot.add("line", Circle_x, Circle_y);
	Plot.add("line", polar_help_line_x, polar_help_line_y);
	Plot.addText(""+polar_tau_1*pow(10,9)+" ns", polar_help_line_x[0]/1, 1-polar_help_line_y[0]/0.6);
	Plot.addText(""+polar_tau_2*pow(10,9)+" ns", polar_help_line_x[1]/1, 1-polar_help_line_y[1]/0.6);
	Plot.add("line", polar_help_line_x, polar_help_line_y);
	Plot.show();
	//plot_temp = getImageID;
	run("Copy");
	plot_width = getWidth;
	plot_height = getHeight;
	close();
	if(f==1) {
		newImage("Polar Plot", "RGB white", plot_width, plot_height, 1);
		plot_window = getImageID;
	}
	else {
		selectImage(plot_window);
		run("Add Slice");
	}
	run("Paste");
}
run("Select None");
setBatchMode("show");

next = getBoolean("Make another polar plot?");
}



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
	if(image!="reference" && smooth_mask==true) run("Median...", "radius="+smooth_radius+" stack");

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

function apply_mask(image,mask,keep) {
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
	if(verbose==true) setBatchMode(true);
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
