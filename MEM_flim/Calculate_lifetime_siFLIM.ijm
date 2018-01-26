/* This ImageJ macro calculates the siFLIM lifetime from opposite-phase MEM-FLIM images or timelapses.
 * As input it requires:
 * 
 * 1. A 'reference' multipage image file (e.g. .TIF) containing a number of phases (e.g. 12) as frames or slices
 * 2. A 'start' conventional FD-FLIM multi-phase image. (This can also be a reference file.)
 * 3. An 'end' conventional FD-FLIM multi-phase image with a different lifetime than the 'start' image. (This can also be a reference file.)
 * 4. A 'sample' multipage image file containing opposite phase MEM-FLIM images or timelapses,
 *    with the two phases defined as slices and the time defined as frames.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 * 
 */

//Image settings
var freq = 40*pow(10,6);					//Modulation frequency in Hz
var n = 1;									//harmonic. Set to 1.
var nr_phases = 12;							//number of phases used for reference, start- and end references
var tau_ref = 3830*pow(10,-12);				//lifetime of the reference in seconds
var siFLIM_phase = 60;						//The chosen phase PHI of the camera. (Images are acquired at phase PHI and PHI+pi)

//Default settings for processing the three multi-phase files
var _last_frame_background_ = false;		//Set to true if in addition to the different phase images a background image is acquired as extra frame. (This frame is then only removed)
var smooth_background = false;				//Smooth this background image
var _create_mask_ = true;
var _autothreshold_ = "Huang";				//Default automatic threshold for creating a mask
var _manual_threshold_adjustment_ = true;	//Option to adjust the automatic threshold.
var _subtract_background_ = false;			//using Difference of Gaussians with sizes [sigma_small] and [sigma_large]
var sigma_small = 0;
var sigma_large = 4;
var _bleach_correct_ = false;				//A simple bleach correction applied on timelapse images. Only used to enable creating a mask with a single threshold
var _despeckle_ = false;					//Remove outliers (e.g. hot pixels) with values larger than [outlier_threshold]
var outlier_threshold = 1000;

//Options for lifetime calculation
var remove_outliers_calibration_coefficient=false;	//
var calibration_coefficient_median_radius = 0;
var show_tau_start_and_end = true;			//Shows the lifetime images of the multi-phase start and end frames
var verbose = false;						//if true, batch mode is disabled (for debugging)
var single_start_lifetime = false;			//Average the 'start' multiphase lifetime to a single value Only works if verbose=true
var segment_calibration_coef = true;		//Calculate a calibration coefficient for each of the four segments of the MEM-FLIM camera as the median of the values per pixel
var single_norm_int = false;				//Use a single normalized intensity for the entire image as the median of the values per pixel
var calibration_range = 1;					//number of images at begin and end used for calibration
var smooth_lifetime = false;				//Smooth the lifetime image with a Mean filter with radius [smooth_radius]
var smooth_radius = 2;						//smoothing for final lifetime image
var lifetime_mask = false;					//Mask the final siFLIM lifetime image

saveSettings();

run("Set Measurements...", "  mean standard median redirect=None decimal=3");
setBackgroundColor(0, 0, 0);
if(nImages>0) run("Close All");


reference_path = File.openDialog("Select a reference file.");
start_path = File.openDialog("Select multiphase image 1.");
end_path = File.openDialog("Select multiphase image 2.");
two_phase_path = File.openDialog("Select a 2-phase file.");
dir = File.getParent(reference_path);

//open and preprocess reference files. Arguments: path, boolean(last frame is background image), boolean(create mask), string(autothreshold), boolean(manual threshold adjustment), boolean(subtract background using Difference of Gaussians), boolean(bleach correct stack), boolean(despeckle)
reference = open_file(reference_path,_last_frame_background_,_create_mask_,_autothreshold_,_manual_threshold_adjustment_,_subtract_background_,_bleach_correct_,_despeckle_);
start_multiphase = open_file(start_path,_last_frame_background_,_create_mask_,_autothreshold_,_manual_threshold_adjustment_,_subtract_background_,_bleach_correct_,_despeckle_);
end_multiphase = open_file(end_path,_last_frame_background_,_create_mask_,_autothreshold_,_manual_threshold_adjustment_,_subtract_background_,_bleach_correct_,_despeckle_);
two_phase = open_file(two_phase_path,false,true,"Huang",true,false,false,false);
dir = File.getParent(two_phase_path)+"\\";
file_name=File.nameWithoutExtension;

if(verbose==false) setBatchMode(true);

//add the correct phases of the 'start' and 'end' frames to the image 
selectWindow(start_multiphase);
setBatchMode("hide");
run("Duplicate...", "duplicate frames="+(siFLIM_phase/(360/nr_phases))%nr_phases + 1);	//select correct phase
rename("start_phase_A");
//waitForUser("start phase A: "+(siFLIM_phase/(360/nr_phases))%nr_phases + 1);
selectWindow(start_multiphase);
run("Duplicate...", "duplicate frames="+(siFLIM_phase/(360/nr_phases) + nr_phases/2)%nr_phases + 1);		//select correct phase
rename("start_phase_B");
//waitForUser("start phase B: "+(siFLIM_phase/(360/nr_phases) + nr_phases/2)%nr_phases + 1);
run("Concatenate...", " title=[start_frame] image1=start_phase_A image2=start_phase_B");
setBatchMode("hide");

selectWindow(end_multiphase);
setBatchMode("hide");
run("Duplicate...", "duplicate frames="+(siFLIM_phase/(360/nr_phases))%nr_phases + 1);
rename("end_phase_A");
//waitForUser("end phase A: "+(siFLIM_phase/(360/nr_phases))%nr_phases + 1);
selectWindow(end_multiphase);
run("Duplicate...", "duplicate frames="+(siFLIM_phase/(360/nr_phases) + nr_phases/2)%nr_phases + 1);
rename("end_phase_B");
//waitForUser("end phase B: "+(siFLIM_phase/(360/nr_phases) + nr_phases/2)%nr_phases + 1);
run("Concatenate...", "  title=[end_frame] image1=end_phase_A image2=end_phase_B");
setBatchMode("hide");

run("Concatenate...", "  title=["+two_phase+"] open image1=start_frame image2=["+two_phase+"] image3=end_frame image4=[-- None --]");


//calculate phi_totals
phi_total_reference = calculate_phi(reference);
phi_total_start = calculate_phi(start_multiphase);
phi_total_end = calculate_phi(end_multiphase);

//calculate phi_system from phi_total_reference
selectWindow(phi_total_reference);
run("Duplicate...", "title=[phi_system] duplicate");
run("Macro...", "code=v=v-atan(2*PI*"+freq+"*"+tau_ref+")");

//add the 'start' and 'end' frames to the mask
selectWindow("mask_"+start_multiphase);
run("Select All");
run("Copy");
run("Select None");
selectWindow("mask_"+two_phase);
getDimensions(width, height, channels, slices, frames);
run("Reverse");
setSlice(frames);
run("Add Slice");	//prepend somehow doesn't work in a macro, so reverse, add frame, and reverse again
run("Reverse");
setSlice(1);
run("Paste");
run("Select None");

selectWindow("mask_"+end_multiphase);
run("Select All");
run("Copy");
run("Select None");
selectWindow("mask_"+two_phase);
getDimensions(width, height, channels, slices, frames);
setSlice(frames);
run("Add Slice");
setSlice(frames+1);
run("Paste");
getDimensions(width, height, channels, slices, frames);
run("Select None");


apply_mask(reference,reference,1);

tau_start = calculate_lifetime(phi_total_start,"start");
tau_end = calculate_lifetime(phi_total_end,"end");

apply_mask(tau_start,start_multiphase,1);
setMinAndMax(0,5);
run("Fire");
if(show_tau_start_and_end==true) setBatchMode("show");

apply_mask(tau_end,end_multiphase,1);
setMinAndMax(0,5);
run("Fire");
if(show_tau_start_and_end==true) setBatchMode("show");

norm_int = normalize_intensity(two_phase);
if(lifetime_mask == true) apply_mask(norm_int,two_phase,1);
run("Make Substack...", "slices=2-"+frames-1);
rename("Normalized_Intensity_masked");
//setBatchMode("show");

get_2phase_start_and_end_norm_int(norm_int);
if(segment_calibration_coef == true) delta_tau_siFLIM = rescale_single_value(norm_int);
else delta_tau_siFLIM = rescale(norm_int);

selectWindow(tau_start);
if(single_start_lifetime == true) {
	List.setMeasurements();
	value = List.getValue("Median");
	print("single tau_start:"+value);
	setColor(value);
	fill();
}

selectWindow(delta_tau_siFLIM);

imageCalculator("Add create 32-bit stack", delta_tau_siFLIM,tau_start);
rename("tau_siFLIM");

if(lifetime_mask == true) apply_mask("tau_siFLIM",two_phase,1);
run("Fire");
resetMinAndMax();
setMinAndMax(0, 5.0000);
setSlice(1);

selectWindow("tau_siFLIM");
if(smooth_lifetime==true) {
	run("Remove NaNs...", "radius="+smooth_radius+" stack");	//Remove the NaNs with a slightly larger radius
	run("Mean...", "sigma="+smooth_radius+" stack");
	if(lifetime_mask == true) apply_mask("tau_siFLIM",two_phase,1);
}


//separate reference frames at start and end
run("Make Substack...", "delete slices=1");
rename("start_tau_siFLIM");
setBatchMode("hide");
//run("Enhance Contrast", "saturated=0.35");
setMinAndMax(0, 5);
selectWindow("tau_siFLIM");
setBatchMode("show");
getDimensions(width, height, channels, slices, frames);
run("Make Substack...", "delete slices="+frames);
rename("end_tau_siFLIM");
setBatchMode("hide");
//run("Enhance Contrast", "saturated=0.35");
setMinAndMax(0, 5);

selectWindow(two_phase);
Stack.setFrame(frames+2);
run("Delete Slice", "delete=frame");	//Delete the start frame (multiphase image 1)
Stack.setFrame(1);
run("Delete Slice", "delete=frame");	//Delete the start frame (multiphase image 1)
run("Enhance Contrast", "saturated=0.35");

//close masks that remain open
close("mask_"+reference);
close("mask_"+start_multiphase);
close("mask_"+end_multiphase);
close("mask_"+two_phase);

setBatchMode(false);

selectWindow("tau_siFLIM");
run("Brightness/Contrast...");
setMinAndMax(0, 5.0000);
restoreSettings();

make_RGB = getBoolean("Create an RGB image and add a calibration bar?");
if(make_RGB == true) {
	waitForUser("Adjust displayed upper and lower ratio in Brightness&Contrast window and hit OK");
	addCalibrationBar();
}

setBatchMode(false);
selectWindow("tau_siFLIM");
saveAs("Tiff", dir+file_name+"_SIFLIM_LIFETIME");


/////// FUNCTIONS ////////

function open_file(path,background,mask,autothreshold,manual_threshold,subtract_background,bleach_correct,despeckle) {	//open and preprocess reference input file
	if(verbose==true) setBatchMode(true);
	//run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default concatenate_series open_all_series view=Hyperstack stack_order=XYCZT");
	open(path);
	name = File.getName(path);
	rename(name);
	run("32-bit");
	getDimensions(width, height, channels, slices, frames);
	if (slices>frames) run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
	else run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Slices (z)] frames=[Frames (t)]");
	getDimensions(width, height, channels, slices, frames);
	if(verbose==true) setBatchMode(false);

	if(background==true) {
		Stack.setFrame(frames);		//last frame is background (dark counts)
		run("Duplicate...", "title=background_"+name);
		if(smooth_background==true) run("Gaussian Blur...", "sigma="+smooth_radius);
		selectWindow(name);
		run("Delete Slice");
		imageCalculator("Subtract stack", name, "background_"+name);
	}
	run("Grays");
	if (mask==true)	create_mask(name, autothreshold, manual_threshold, subtract_background,bleach_correct,despeckle);

	if(background==true && verbose==false) close("background_"+name);
	return name;
}


function background_subtract(image) {
	setBatchMode(true);
	showStatus("subtracting background...");
	selectWindow(image);
	run("Duplicate...", "title=large_blur duplicate range=[]");
	run("Remove Outliers...", "radius="+sigma_large+" threshold=50 which=Bright stack");
	selectWindow(image);
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


function create_mask(image, autothreshold, manual_threshold, subtract_background,bleach_correct, despeckle) {
	selectWindow(image);
	run("Select None");
	run("Z Project...", "projection=[Sum Slices] all");	//Do masking on maximum intensity of all phases on first frame.
	rename("create_mask_image");
	run("16-bit");
	if(subtract_background==true) background_subtract("create_mask_image");
	resetThreshold();
	if(bleach_correct==true) {
	run("Bleach Correction", "correction=[Simple Ratio] background=0");
	close("create_mask_image");
	selectWindow("DUP_create_mask_image");
	rename("create_mask_image");
	}
	if(despeckle==true) run("Remove Outliers...", "radius=0 threshold="+outlier_threshold+" which=Bright stack");
	run("Threshold...");
	setAutoThreshold(autothreshold+" dark stack");
	run("Threshold...");
	if(manual_threshold==true) waitForUser("adjust threshold if necessary");
	run("Make Binary", "stack");
	rename("mask_"+image);
	run("Divide...", "value=255 stack");
	selectWindow(image);
	resetThreshold();
}


function apply_mask(image,mask,frame) {
	selectWindow(image);
	resetThreshold();
	if(frame==1) imageCalculator("Multiply 32-bit stack", image,"mask_"+mask);
	else {
		selectWindow("mask_"+mask);
		setSlice(frame);
		run("Duplicate...", "title=mask_frame");
		imageCalculator("Multiply 32-bit stack", image,"mask_frame");
		close("mask_frame");
	}
	close(image);
	selectWindow("Result of "+image);
	rename(image);

	//remove edge pixels
	run("Select All");
	run("Enlarge...", "enlarge=-2");
	setMinAndMax(-65535,0);
	run("Clear Outside", "stack");
	run("Select None");
	
	getStatistics(area, mean, stddev);

	getDimensions(image_width, image_height, image_channels, image_slices, image_frames);
	for(i=1;i<=image_frames;i++) {
		if(image_frames>1) Stack.setFrame(i);
		changeValues(0, 0, -10000);
		setThreshold(-9999, 65536);
		run("NaN Background", "slice");
	}
	resetThreshold();
	resetMinAndMax();
}


function calculate_phi(image) {
	selectWindow(image);
	if(verbose==true) setBatchMode(true);

	run("Duplicate...", "title=[SIN_"+image+"] duplicate slices=[] frames=[]");
	run("Duplicate...", "title=[COS_"+image+"] duplicate slices=[] frames=[]");
	//Create Fcos
	selectWindow("COS_"+image);
	for(phi=0;phi<nr_phases;phi++) {
		Stack.setFrame(phi+1);		//phi=0 starts at frame 1
		run("Multiply...", "value="+cos(2*PI*n*phi/nr_phases));		//multiply with cosine
	}
	run("Z Project...", "projection=[Sum Slices]");
	rename("Fcos_"+image);

	//Create Fsin
	selectWindow("SIN_"+image);
	for(phi=0;phi<nr_phases;phi++) {
		Stack.setFrame(phi+1);
		run("Multiply...", "value="+sin(2*PI*n*phi/nr_phases));		//multiply with sine
	}
	run("Z Project...", "projection=[Sum Slices]");
	rename("Fsin_"+image);
	
	imageCalculator("Divide create 32-bit", "Fcos_"+image,"Fsin_"+image);	//F_cosine divided by F_sine, because integrating a sine gives a cosine
	run("Macro...", "code=v=atan(v)");
	rename("Phi_total_"+image);		//retreive the phase

	//Make sure the histogram is smooth (due to periodic boundary conditions)
	getDimensions(width, height, channels, slices, frames);
	List.setMeasurements();
	median = List.getValue("Median");
	if(median > 0) {
		pixel=0;
		for(x=0;x<width;x++) {
			for(y=0;y<height;y++) {
			value = getPixel(x,y);
			if(value<0) setPixel(x,y,value+PI);
			pixel++;
			}
		}
	}
	else {
		pixel=0;
		for(x=0;x<width;x++) {
			for(y=0;y<height;y++) {
			value = getPixel(x,y);
			if(value>0) setPixel(x,y,value-PI);
			pixel++;
			}
		}
	}

	if(verbose==true) setBatchMode(false);	
	return "Phi_total_"+image;		//return the phase
}


function calculate_lifetime(phi_total,timepoint) {
	selectWindow(phi_total);
	if(verbose==true) setBatchMode(true);
	imageCalculator("Subtract create stack", phi_total,"phi_system");
	run("Duplicate...", "title=[Phi total - Phi system] duplicate");
	run("Macro...", "code=v=(tan(v)/(2*PI*"+freq+"))*1000000000 stack");
	rename("tau_"+timepoint);
	if(verbose==true) setBatchMode(false);
	return "tau_"+timepoint;
}


function normalize_intensity(image) {
	if(verbose==true) setBatchMode(true);
	showStatus("Normalizing intensity...");
	selectWindow(image);
	setSlice(1);
	run("Reduce Dimensionality...", "  frames keep");
	rename("phase1");
	selectWindow(image);
	setSlice(2);
	run("Reduce Dimensionality...", "  frames keep");
	rename("phase2");
	imageCalculator("Add create 32-bit stack", "phase1","phase2");
	rename("I+Ipi");
	imageCalculator("Subtract create 32-bit stack", "phase1","phase2");
	rename("I-Ipi");
	imageCalculator("Divide create 32-bit stack", "I-Ipi","I+Ipi");
	rename("normalized_intensity");
	if(verbose==true) setBatchMode(false);
	return "normalized_intensity";
}


function get_2phase_start_and_end_norm_int(norm_int) {
	selectWindow(norm_int);
	getDimensions(width, height, channels, slices, frames);
	
	//calculate start normalized intensity
	run("Duplicate...", "title=norm_int_start duplicate range=1-"+calibration_range);
	if(calibration_range>1) {
		run("Z Project...", "projection=[Average Intensity]");
		rename("projection");
		close("norm_int_start");
		selectWindow("projection");
		rename("norm_int_start");
	}
	if(single_norm_int == true) {	//Make the calibration coefficient a single value
	apply_mask("norm_int_start",two_phase,1);
	List.setMeasurements();
	value = List.getValue("Median");
	print("norm_int_start:"+value);
	setColor(value);
	fill();
	}

	//calculate end normalized intensity
	selectWindow(norm_int);
	run("Duplicate...", "title=norm_int_end duplicate range="+frames-calibration_range+1+"-"+frames);
	if(calibration_range>1) {
		run("Z Project...", "projection=[Average Intensity]");
		rename("projection");
		close("norm_int_end");
		selectWindow("projection");
		rename("norm_int_end");
	}
	if(single_norm_int == true) {	//Make the calibration coefficient a single value
	apply_mask("norm_int_end",two_phase,frames);
	List.setMeasurements();
	value = List.getValue("Median");
	print("norm_int_end:"+value);
	setColor(value);
	fill();
	}
}


function rescale(norm_int) {
	selectWindow(norm_int);
	getDimensions(width, height, channels, slices, frames);

	//calculate static delta normalized intensity (end minus start)
	imageCalculator("Subtract create 32-bit stack", "norm_int_end","norm_int_start");
	rename("delta_norm_int_end_min_start");

	//calculate running delta normalized intensity (end minus start)
	imageCalculator("Subtract create 32-bit stack", norm_int,"norm_int_start");
	rename("delta_norm_int");

	//calculate delta 12-phase tau
	imageCalculator("Subtract create 32-bit stack", tau_end, tau_start);
	rename("delta_tau_multiphase");

	//calculate calibration coefficient
	imageCalculator("Divide create 32-bit stack", "delta_tau_multiphase","delta_norm_int_end_min_start");
	if(verbose==true) setBatchMode(false);
	rename("calibration coefficient");
	if(remove_outliers_calibration_coefficient==true) {
		setThreshold(1,65535);
		run("Set Measurements...", "mean median limit redirect=None decimal=3");
		List.setMeasurements();
		median_coefficient = List.getValue("Median");
		run("Remove Outliers...", "radius=3 threshold="+median_coefficient*2+" which=Bright");	//Flatten noisy pixels with high values to the median*2
		run("Remove Outliers...", "radius=3 threshold="+median_coefficient/2+" which=Dark");	//Flatten noisy pixels with low values to the median/2
		resetThreshold();
	}
	if(calibration_coefficient_median_radius>0) run("Median...", "radius="+calibration_coefficient_median_radius);	//smooth if desired

	//multiply normalized intensity with calibration coefficient
	imageCalculator("Multiply create 32-bit stack", "delta_norm_int","calibration coefficient");
	rename("delta_tau_siFLIM");
	return "delta_tau_siFLIM";
}


function rescale_single_value(norm_int) {
	selectWindow("norm_int_start");
	apply_mask("norm_int_start",start_multiphase,1);
	makeRectangle(0, 0, 528, 131);
	List.setMeasurements();
	mean_norm_int_start_1 = List.getValue("Median");
	makeRectangle(0, 131, 528, 130);
	List.setMeasurements();
	mean_norm_int_start_2 = List.getValue("Median");
	makeRectangle(0, 261, 528, 130);
	List.setMeasurements();
	mean_norm_int_start_3 = List.getValue("Median");
	makeRectangle(0, 391, 528, 130);
	List.setMeasurements();
	mean_norm_int_start_4 = List.getValue("Median");
	run("Select None");

	selectWindow("norm_int_end");
	apply_mask("norm_int_end",end_multiphase,1);
	setPixel(0,0,0);
	setPixel(0,131,0);
	setPixel(0,261,0);
	setPixel(0,391,0);
	makeRectangle(0, 0, 528, 131);
	List.setMeasurements();
	mean_norm_int_end_1 = List.getValue("Median");
	makeRectangle(0, 131, 528, 130);
	List.setMeasurements();
	mean_norm_int_end_2 = List.getValue("Median");
	makeRectangle(0, 261, 528, 130);
	List.setMeasurements();
	mean_norm_int_end_3 = List.getValue("Median");
	makeRectangle(0, 391, 528, 130);
	List.setMeasurements();
	mean_norm_int_end_4 = List.getValue("Median");
	run("Select None");

	//calculate static delta normalized intensity (end minus start)
	mean_delta_norm_int_end_min_start_1 = mean_norm_int_end_1 - mean_norm_int_start_1;	//actually using the medians (better results)
	mean_delta_norm_int_end_min_start_2 = mean_norm_int_end_2 - mean_norm_int_start_2;	//actually using the medians (better results)
	mean_delta_norm_int_end_min_start_3 = mean_norm_int_end_3 - mean_norm_int_start_3;	//actually using the medians (better results)
	mean_delta_norm_int_end_min_start_4 = mean_norm_int_end_4 - mean_norm_int_start_4;	//actually using the medians (better results)

	print("median_norm_int_start_1:\t"+mean_norm_int_start_1);
	print("median_norm_int_start_2:\t"+mean_norm_int_start_2);
	print("median_norm_int_start_3:\t"+mean_norm_int_start_3);
	print("median_norm_int_start_4:\t"+mean_norm_int_start_4);
	print("median_norm_int_end_1:\t"+mean_norm_int_end_1);
	print("median_norm_int_end_2:\t"+mean_norm_int_end_2);
	print("median_norm_int_end_3:\t"+mean_norm_int_end_3);
	print("median_norm_int_end_4:\t"+mean_norm_int_end_4);	
	print("delta_norm_int_end_min_start_1:\t"+mean_delta_norm_int_end_min_start_1);
	print("delta_norm_int_end_min_start_2:\t"+mean_delta_norm_int_end_min_start_2);
	print("delta_norm_int_end_min_start_3:\t"+mean_delta_norm_int_end_min_start_3);
	print("delta_norm_int_end_min_start_4:\t"+mean_delta_norm_int_end_min_start_4);
	//calculate running delta normalized intensity (end minus start)
	selectWindow(norm_int);
	run("Duplicate...", "title=delta_norm_int duplicate");

	makeRectangle(0, 0, 528, 131);
	run("Subtract...", "value="+mean_norm_int_start_1+" stack");
	makeRectangle(0, 131, 528, 130);
	run("Subtract...", "value="+mean_norm_int_start_2+" stack");
	makeRectangle(0, 261, 528, 130);
	run("Subtract...", "value="+mean_norm_int_start_3+" stack");
	makeRectangle(0, 391, 528, 130);
	run("Subtract...", "value="+mean_norm_int_start_4+" stack");
	run("Select None");

	//calculate delta 12-phase tau
	selectWindow(tau_start);

	getStatistics(area, mean_tau_start);
	print("mean tau_start: "+mean_tau_start);
	selectWindow(tau_end);
	
	getStatistics(area, mean_tau_end);
	print("mean tau_end: "+mean_tau_end);
	mean_delta_tau_multiphase = mean_tau_end - mean_tau_start;

	//calculate calibration coefficient
	calibration_coefficient_1 = mean_delta_tau_multiphase / mean_delta_norm_int_end_min_start_1;
	calibration_coefficient_2 = mean_delta_tau_multiphase / mean_delta_norm_int_end_min_start_2;
	calibration_coefficient_3 = mean_delta_tau_multiphase / mean_delta_norm_int_end_min_start_3;
	calibration_coefficient_4 = mean_delta_tau_multiphase / mean_delta_norm_int_end_min_start_4;

	print("mean_delta_tau_multiphase:\t"+mean_delta_tau_multiphase);
	print("calibration coefficient_1:\t"+calibration_coefficient_1);
	print("calibration coefficient_2:\t"+calibration_coefficient_2);
	print("calibration coefficient_3:\t"+calibration_coefficient_3);
	print("calibration coefficient_4:\t"+calibration_coefficient_4);

	//create image with the 4 calibration coefficients
	selectWindow(norm_int);
	run("Duplicate...", "title=calibration_coefficient");
	makeRectangle(0, 0, 528, 131);
	setColor(calibration_coefficient_1);
	fill();
	makeRectangle(0, 131, 528, 130);
	setColor(calibration_coefficient_2);
	fill();
	makeRectangle(0, 261, 528, 130);
	setColor(calibration_coefficient_3);
	fill();
	makeRectangle(0, 391, 528, 130);
	setColor(calibration_coefficient_4);
	fill();
	run("Select None");
	//setBatchMode("show");

	//multiply normalized intensity with calibration coefficient
	selectWindow("delta_norm_int");
	imageCalculator("Multiply create 32-bit stack", "delta_norm_int","calibration_coefficient");
	rename("delta_tau_siFLIM");

	return "delta_tau_siFLIM";
}


function cleanup(image, threshold) {
	selectWindow(image);
	run("Remove Outliers...", "radius=0 threshold="+threshold+" which=Dark stack");
	run("Remove Outliers...", "radius=0 threshold="+-threshold+" which=Bright stack");
	run("Remove NaNs...", "radius=1 stack");
}


function addCalibrationBar() {
	if (bitDepth==24)
 		exit("Bars cannot be added to RGB images: "+getTitle);
	setBatchMode(true);
	nS = nSlices;
	stackID = getImageID();
	setSlice(1);
	run("Calibration Bar...", "location=[Upper Left] fill=Black label=White number=6 decimal=2 font=12 zoom=1");
	barID = getImageID();
	for (n=2; n<=nS; n++) {
		showProgress(n, nS);
		selectImage(stackID);
		setSlice(n);
		run("Calibration Bar...", "location=[Upper Left] fill=Black label=White number=6 decimal=2 font=12 zoom=1");
		run("Cut");
		close();
		selectImage(barID);
		run("Add Slice");
		run("Paste");
	}
	run("Select None");
	setSlice(1);
	selectImage(stackID);
	setSlice(1);
	selectImage(barID);
	setBatchMode(false);
}


function replace_NaN_by_local_mean(image, radius) {
	run("Select None");
	getDimensions(width, height, channels, slices, frames);
	run("Duplicate...", "title="+image+"_NaNs_replaced duplicate");
	image2 = getTitle();
	if(verbose==true) setBatchMode(true);
	for(f=0;f<=frames;f++) {
		Stack.setFrame(f);
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
