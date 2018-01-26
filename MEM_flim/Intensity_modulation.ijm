// Macro to modulate the intensity of a ratio/lifetime image with another image.
// Input: intensity stack & ratio/lifetime stack (colored LUT)
// Output: an RGB stack with lifetime in color LUT intensity stack as Brightness.
// A Calibration bar is included if the input image is not RGB. 

position = "Lower Right";	//position of calibration bar

if(nImages>0) run("Close All");

intensity_image = File.openDialog("Select intensity image or stack");
open(intensity_image);
intensity_image = getTitle();
lifetime_image = File.openDialog("Select lifetime/ratio image or stack");
open(lifetime_image);
lifetime_image = getTitle();
getDimensions(width, height, channels, slices, frames);

selectWindow(intensity_image);
run("Select None");

getDimensions(width, height, channels, int_slices, int_frames);
run("Grays");
run("Brightness/Contrast...");
waitForUser("Adjust Brightness&Contrast for the intensity image and hit OK");

selectWindow(lifetime_image);
run("Select None");

run("Duplicate...", "title=dup_lifetime duplicate");
run("Brightness/Contrast...");
setMinAndMax(1, 4);
smooth = getBoolean("smooth lifetime image?");
if (smooth==true) {
	run("Remove NaNs...", "radius=2 stack");
//	run("Mean...", "radius=0.5 stack");
}
if (bitDepth!=24) {
	waitForUser("Adjust LUT (not Grays), upper and lower levels in Brightness&Contrast window and hit OK");
	run("Calibration Bar...", "location=["+position+"] fill=Black label=White number=4 decimal=1 font=12 zoom=1 overlay");
	run("RGB Color");
}
setBatchMode(true);


for(i=1;i<=frames;i++) {
	selectWindow("dup_lifetime");
	run("Make Substack...", "slices="+i);
	run("HSB Stack");
	rename("frame_"+i);
	selectWindow(intensity_image);
	if(int_frames>1) Stack.setFrame(i);
	run("Copy");
	selectWindow("frame_"+i);
	Stack.setChannel(3);
	run("Paste");
	run("RGB Color");
}

run("Images to Stack", "name=Stack title=frame");
run("Insert...", "source=Stack destination=dup_lifetime x=0 y=0");
close("Stack");
selectWindow("dup_lifetime");
rename(lifetime_image+"_intensity_modulated");
//run("Flatten", "stack");

setBatchMode(false);
