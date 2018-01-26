/* The current prototype of the MEMFLIM camera (MEMFLIM3) has a relatively high background, differing for each pixel.
 * This ImageJ macro subtracts a deinterlaced background image (acquired without illumination and with the same exposure time)
 * from a deinterlaced MEMFLIM .TIF file.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 */


if(nImages>0) run("Close All");

series_path	= File.openDialog("Select a deinterlaced MEMFLIM 12-phase or series .TIF file.");
background_path = File.openDialog("Select a deinterlaced MEMFLIM BACKGROUND .TIF file.");

series_stack = open_file(series_path);
file_name = File.name;
file_name_without_extension = File.nameWithoutExtension;
getDimensions(width, height, channels, slices, frames);
dir = File.getParent(series_path);
background_stack = open_file(background_path);

//background
run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
run("Z Project...", "projection=[Average Intensity] all");
run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
background_image = getTitle();
run("Stack Splitter", "number=2");
//run("Deinterleave", "how=2");
selectWindow("slice0001_"+background_image);
rename("background_odd");
selectWindow("slice0002_"+background_image);
rename("background_even");

selectWindow(series_stack);

newdir= dir+"\\background_subtracted\\";
File.makeDirectory(newdir);
file_list = getFileList(dir); //get filenames of directory
extension_length=(lengthOf(file_name)- lengthOf(file_name_without_extension)-1);
extension = substring(file_name, (lengthOf(file_name)-extension_length));

j=0;
image_list=newArray(file_list.length);	//Dynamic array size doesn't work on some computers, so first make image_list the maximal size and then trim.
for(i=0; i<file_list.length; i++){
	if (endsWith(file_list[i],extension)) {
		image_list[j] = file_list[i];
		j++;
	}
}
image_list = Array.trim(image_list, j);	//Trimming the array of images
print("\\Clear");
print("Directory contains "+file_list.length+" items, of which "+image_list.length+" "+extension+" files.");
all_files = getBoolean("Subtract this background for all "+image_list.length+" ."+extension+" files in the directory?");
if(all_files==false) {
	image_list=Array.trim(image_list,1);
	image_list[0]=file_name;
}
else close();

setBatchMode(true);


for(f=0;f<image_list.length;f++) {

showStatus("Background subtracting MEMFLIM images...");
showProgress(f/image_list.length);
print(dir+"\\"+image_list[f]);
series_stack = open_file(dir+"\\"+image_list[f]);
print(image_list[f]);

file_name_without_extension = File.nameWithoutExtension;
getDimensions(width, height, channels, slices, frames);
print("frames: "+frames);
original=getTitle();

//image
selectWindow(series_stack);
Stack.setSlice(1);
run("Reduce Dimensionality...", "  frames keep");
rename("series_odd");
selectWindow(series_stack);
Stack.setSlice(2);
run("Reduce Dimensionality...", "  frames keep");
rename("series_even");

//subtract, recombine and save
imageCalculator("Subtract 32-bit stack", "series_odd", "background_odd");
rename("series_odd_bgsubtr");
imageCalculator("Subtract 32-bit stack", "series_even", "background_even");
rename("series_even_bgsubtr");
run("Concatenate...", "  title=[Concatenated Stacks] keep open image1=series_odd_bgsubtr image2=series_even_bgsubtr image3=[-- None --]");
run("Stack to Hyperstack...", "order=xyctz channels=1 slices=2 frames="+frames+" display=Color");
run("Enhance Contrast", "saturated=0.35");
setBatchMode("show");

print("Saving as "+newdir+substring(series_stack,0,lengthOf(series_stack)-4)+"_bs");
saveAs("Tiff", newdir+substring(series_stack,0,lengthOf(series_stack)-4)+"_bs");
run("Close");

close("series_odd");
close("series_even");
close("series_odd_bgsubtr");
close("series_even_bgsubtr");
//setBatchMode(false);
}


function open_file(path) {
	filename = File.name;
	extension_length=(lengthOf(filename)- lengthOf(File.nameWithoutExtension)-1);
	extension = substring(filename, (lengthOf(filename)-extension_length));
	//open and preprocess reference file
	if(extension=="raw" || extension=="RAW") {
		file_length = File.length(path);
		frames = file_length/1098240;
		print("Opening "+path+": "+frames+" frames.");
		if(frames != parseInt(frames)) exit("Error reading the file. Unknown number of frames.");
		run("Raw...", "open=["+path+"] image=[16-bit Unsigned] width=528 height=1040 offset=0 number="+frames+" gap=0 little-endian");
	}
	else {
		open(path);
		getDimensions(width, height, channels, slices, frames);
		print("Opening "+path+": "+frames+" frames.");
	}
	image=getTitle();
	getDimensions(width, height, channels, slices, frames);
	if (slices>frames) {
		run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
		getDimensions(width, height, channels, slices, frames);
	}
	run("Grays");
	return image;
}
