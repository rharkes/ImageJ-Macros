/* Splits multi-series files (e.g. .lif, .dv, .czi) into multiple .TIFF files using BioFormats Importer
 * and saves them on disk.
 * 
 * BvdB, 2014
 * 
 */

saveSettings();

print("\\Clear");
run("Clear Results");

var nr_series;
var file_name;
var format;
var projection = false;
var projection_type = "Max Intensity";

if(nImages>0) run("Close All");
path = File.openDialog("Select a File");

Dialog.create("projection settings (for series with multiple z-slices");
projection_items = newArray("Average Intensity", "Max Intensity", "Min Intensity", "Sum Slices", "Standard Deviation", "Median");
projection_items = newArray("Average Intensity", "Max Intensity", "Min Intensity", "Sum Slices", "Standard Deviation", "Median");

Dialog.addCheckbox("make Z-projection", projection);
Dialog.setInsets(-23, 30, 5);
Dialog.addChoice("                             ", projection_items, "Max Intensity")
Dialog.show();

projection = Dialog.getCheckbox();
projection_type = Dialog.getChoice();

//define file suffix for every projection type
if (projection_type == "Average Intensity") projection_suffix = "_AVG";
if (projection_type == "Max Intensity") projection_suffix = "_MAX";
if (projection_type == "Min Intensity") projection_suffix = "_MIN";
if (projection_type == "Sum Slices") projection_suffix = "_SUM";
if (projection_type == "Standard Deviation") projection_suffix = "_STD";
if (projection_type == "Median") projection_suffix = "_MED";

setBatchMode(true);

run("Bio-Formats Macro Extensions");
run("Bio-Formats Importer", "open=["+path+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_1");
dir = getDirectory("image");
file_name = getInfo("image.filename");

Ext.getFormat(path, format);

getPixelSize(unit, pw, ph, pd);
frame_interval = Stack.getFrameInterval();
getDimensions(width, height, channels, slices, frames);

extension_length=(lengthOf(file_name)- lengthOf(File.nameWithoutExtension)-1);
extension = substring(file_name, (lengthOf(file_name)-extension_length));
file_list = getFileList(dir); //get filenames of directory

//make a list of images with 'extension' as extension.
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
print("Directory contains "+file_list.length+" files, of which "+image_list.length+" ."+extension+" ("+format+") files.");

current_image_nr=0;
do {
	run("Close All");
	file_name = image_list[current_image_nr];		//retrieve file name from image list
	//opening multi-series files and saving them as separate .ome.tif
	Ext.setId(dir+file_name);
	Ext.getSeriesCount(nr_series);
	print("Processing file "+current_image_nr+1+"/"+image_list.length+", series "+i+1+"/"+nr_series+": "+dir+name+"...");
	
	for(i=0;i<nr_series;i++) {
		run("Bio-Formats Importer", "open=["+dir+file_name+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+i+1);
		name = getTitle();
		name = replace(name,"\\/","-");	//replace slashes by dashes in the name
		//run("Bio-Formats Exporter", "save=["+dir+name+".ome.tif] compression=LZW");
		//LOCI doesn't save hyperstacks :-(
		print(dir+name);
		Ext.getSizeZ(sizeZ);
		if(sizeZ>1 && projection==true) {
			run("Z Project...", " projection=["+projection_type+"] all");
			saveAs("Tiff",dir+name+projection_suffix);
			close();
		}
		saveAs("Tiff",dir+name);
		close();
	}
	current_image_nr++;
} while (current_image_nr<image_list.length);




setBatchMode(false);

restoreSettings();