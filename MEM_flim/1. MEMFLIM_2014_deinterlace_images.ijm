/* Raw images from the MEMFLIM camera have data from the two registers interlaced (odd and even lines)
 * This ImageJ macro opens all .raw files in a directory and saves a deinterlaced image or timelapse
 * as a .TIF file with the two registers as z-slices.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 */


if (nImages>0) run("Close All");

path = File.openDialog("Select a .RAW file in the directory to be de-interlaced...");
//open(path);
run("Raw...", "open=["+path+"] image=[16-bit Unsigned] width=528 height=1040 offset=0 number=99999 gap=0 little-endian");
file_name = getInfo("image.filename");
dir = getDirectory("image");
newdir= dir+"\\deinterlaced\\";
File.makeDirectory(newdir);
file_list = getFileList(dir); //get filenames of directory
extension_length=(lengthOf(file_name)- lengthOf(File.nameWithoutExtension)-1);
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
print("Directory contains "+file_list.length+" files, of which "+image_list.length+" "+extension+" files.");
all_files = getBoolean("Deinterlace all "+image_list.length+" ."+extension+" files in the directory?");
print("\nDeinterlacing images:\n");

setBatchMode(true);

if(all_files==false) {
	image_list=Array.trim(image_list,1);
	image_list[0]=path;
}
else close();

for(f=0;f<image_list.length;f++) {

	showStatus("Splitting MEMFLIM images...");
	showProgress(f/image_list.length);
	print(image_list[f]);
	//open(image_list[f]);
	if(all_files==true) run("Raw...", "open=["+dir+image_list[f]+"] image=[16-bit Unsigned] width=528 height=1040 offset=0 number=99999 gap=0 little-endian");
	MEMFLIM_original = getTitle();
	file_name_without_extension = File.nameWithoutExtension;

	getDimensions(width, height, channels, slices, frames);
	if(frames==1 && slices>frames) {
		run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
		getDimensions(width, height, channels, slices, frames);
	}
	//print(width, height, channels, slices, frames);
	line=newArray(width);
	getMinAndMax(min, max);
	if(min>=32768) {
		run("Subtract...", "value=32768 stack");	//some MEMFLIM images start at 32768
		min=min-32768;
		max=max-32768;
		resetMinAndMax();
	}

	//de-interlacing
	selectWindow(MEMFLIM_original);
	run("Scale...", "x=1.0 y=0.5 z=1.0 width=528 height=520 interpolation=None create process title=odd");
	selectWindow(MEMFLIM_original);
	run("Translate...", "x=0 y=-1 interpolation=None stack");
	run("Scale...", "x=1.0 y=0.5 z=1.0 width=528 height=520 interpolation=None create process title=even");
	
	run("Concatenate...", "  title=[Concatenated Stacks] open image1=odd image2=even image3=[-- None --]");
	run("Stack to Hyperstack...", "order=xyctz channels=1 slices=2 frames="+frames+" display=Color");
	selectWindow("Concatenated Stacks");
	saveAs("Tiff", newdir+file_name_without_extension+"_di");
	close();

	selectWindow(MEMFLIM_original);
	close();
	
	setBatchMode(false);
}
print("\nfinished");