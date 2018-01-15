//This macro converts all series into .TIF files

run("Bio-Formats Macro Extensions");

path = File.openDialog("Select a File");
Ext.setId(path);
Ext.getFormat(path, format);
Ext.getSeriesCount(nr_series);
//Ext.getCurrentFile(filename);
dir = File.getParent(path)+"\\";
if (!File.exists(dir+"bgsubtr")) {
	File.makeDirectory(dir+"bgsubtr");
	print("Creating output directory: "+dir+"bgsubtr");
}
savedir = dir+"bgsubtr"+"\\";
filename = substring(path, lengthOf(dir), lengthOf(path));
Ext.isThisType(path, thisType);

print("File type: "+format);
if (thisType!="true") exit("This file cannot be opened using Bio-Formats");

last_index_of_dot = lastIndexOf(filename, ".");
extension = substring(filename, last_index_of_dot+1, lengthOf(filename));

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
print("Directory contains "+file_list.length+" files, of which "+image_list.length+" ."+extension+" files.");
process_all=getBoolean("Process all "+image_list.length+" "+extension+" files in this directory?");


current_file_nr=0;
//Loop over all files
do {
	if(process_all==true) {
		run("Close All");
		file_name = image_list[current_file_nr];		//retrieve file name from image list
	}
	else file_name = File.getName(path);
	Ext.setId(dir+file_name);
	Ext.getSeriesCount(nr_series);
	
	//Loop over all series in the file
	for(n=0;n<nr_series;n++) {
		Ext.setSeries(n);	//numbering apparently starts at 0...
		Ext.getSizeT(sizeT);
		Ext.getSeriesName(seriesName);

		if(sizeT>1) {	//else the serie is not a movie and will be skipped
			print("Processing file "+current_file_nr+1+"/"+image_list.length+", series "+n+1+"/"+nr_series+": "+dir+file_name+" - "+seriesName+"... ("+sizeT+" frames)");
			run("Bio-Formats Importer", "open=["+dir+file_name+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+n+1);

			//...
			//hier image processing code
			//...
		}
		else print("skipping file "+current_file_nr+1+"/"+image_list.length+", series "+n+1+"/"+nr_series+": "+dir+file_name+" - "+seriesName+"... ("+sizeT+" frame)");
	}
	current_file_nr++;
} while (process_all==true && current_file_nr<image_list.length);
