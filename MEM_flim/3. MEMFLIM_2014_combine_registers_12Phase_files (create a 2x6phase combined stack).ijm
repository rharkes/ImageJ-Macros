/* This ImageJ macro converts 12-phase MEMFLIM .TIF images (containing 12 images from the 'even' register and 12 images from the 'odd' register as z-slices)
 * to a single 12-phase stack, by concatenating only the first 6 images of both registers.
 * 
 * Written by Bram van den Broek - Netherlands Cancer Institute, 2013-2015
 * For support please email to b.vd.broek@nki.nl
 */

if(nImages>0) run("Close All");

path= File.openDialog("Select a 2x12-phase MEMFLIM .TIF file");
open(path);
dir = File.getParent(path);
file_name = File.name;

newdir= dir+"\\registers_combined\\";
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
all_files = getBoolean("Combine registers for all "+image_list.length+" ."+extension+" files in the directory?");
if(all_files==false) {
	image_list=Array.trim(image_list,1);
	image_list[0]=path;
}
else close();
print("\nCombining images:\n");

setBatchMode(true);

for(f=0;f<image_list.length;f++) {

	showStatus("Combining MEMFLIM images...");
	showProgress(f/image_list.length);
	open(image_list[f]);
	print(image_list[f]);
	
	file_name_without_extension = File.nameWithoutExtension;
	getDimensions(width, height, channels, slices, frames);
	original=getTitle();
	
	if (slices>frames) {
		run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
		getDimensions(width, height, channels, slices, frames);
	}
	setBatchMode("show");
	setBatchMode(false);
	run("Deinterleave", "how=2");
	setBatchMode(true);
	
	for(i=0;i<frames/12;i++) {
		selectWindow(original+" #1");
		//run("Duplicate...", "title=upper_six duplicate frames="+(12*i)+1+"-"+(12*i)+6);
		run("Duplicate...", "title=upper_six duplicate range="+(12*i)+1+"-"+(12*i)+6); //sometimes you need this
		selectWindow(original+" #2");
		//run("Duplicate...", "title=lower_six duplicate frames="+(12*i)+1+"-"+(12*i)+6);
		run("Duplicate...", "title=lower_six duplicate range="+(12*i)+1+"-"+(12*i)+6); //sometime you need this
		run("Concatenate...", "  title=[frame_"+i+1+"] stack1=upper_six stack2=lower_six");
		if(i>0) run("Concatenate...", "stack1=frame_1 stack2=frame_"+i+1+" title=frame_1");
	}
	setBatchMode("show");
	close(original+" #1");
	close(original+" #2");
//LITTLE BIT MESSED UP HERE. SHOULD NOT BE CLOSED
	saveAs("Tiff", newdir+file_name_without_extension+"_combined");
	if(all_files==true) close();
//	saveAs("Tiff", substring(path,0,lengthOf(path)-4)+"_combined");

}
