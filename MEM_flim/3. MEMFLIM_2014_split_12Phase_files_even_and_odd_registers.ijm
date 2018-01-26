/* This ImageJ macro converts 12-phase MEMFLIM .TIF images (containing 12 images from the 'even' register and 12 images from the 'odd' register as z-slices)
 * into two separate 12-phase stacks for both registers.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 */


if(nImages>0) run("Close All");

path=File.openDialog("Select a 2x12-phase MEMFLIM .TIF file");
dir = File.getParent(path);
filename = File.name;
extension_length=(lengthOf(filename)- lengthOf(File.nameWithoutExtension)-1);
extension = substring(filename, (lengthOf(filename)-extension_length));
newdir_even = dir+"\\12-phase even\\";
newdir_odd = dir+"\\12-phase odd\\";
File.makeDirectory(newdir_even);
File.makeDirectory(newdir_odd);
open(path);
getDimensions(width, height, channels, slices, frames);
print("Opening "+path+": "+frames+" frames.");
original=getTitle();

j=0;
file_list = getFileList(dir); //get filenames of directory
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
all_files = getBoolean("Combine registers for all "+image_list.length+" ."+extension+" files in the directory?");
if(all_files==false) {
	image_list=Array.trim(image_list,1);
	image_list[0]=path;
}
else close();
print("\nCombining images:\n");

//setBatchMode(true);

for(f=0;f<image_list.length;f++) {

	showStatus("splitting MEMFLIM registers...");
	showProgress(f/image_list.length);
	open(image_list[f]);
	print(image_list[f]);
	
	file_name_without_extension = File.nameWithoutExtension;
	getDimensions(width, height, channels, slices, frames);
	original=getTitle();

	if(slices>frames) {
		run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
		getDimensions(width, height, channels, slices, frames);
	}
	run("Deinterleave", "how=2");

	selectWindow(original+" #1");
	saveAs("Tiff", newdir_odd+file_name_without_extension+"_ODD");
	run("Close");
	selectWindow(original+" #2");
	saveAs("Tiff", newdir_even+file_name_without_extension+"_EVEN");
	run("Close");
}