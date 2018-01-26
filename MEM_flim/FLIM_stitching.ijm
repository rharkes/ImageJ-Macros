/*
 * Macro to stitch FLIM images. Uses the plugin from Stephan Preibisch which is incorporated in FIJI.
 * Bram van den Broek & Rolf Harkes, The Netherlands Cancer Institute, 2017
 */

var x_span = 10;	//number of images in x-direction
var y_span = 10;	//number of images in y-direction
var overlap = 30;	//Initial tile overlap
var motive_I = "Sample_p{iii}_I";
var compute_overlap = true;
var tile_config_file = "TileConfiguration.txt";

print("\\Clear");
run("Clear Results");

dir = getDirectory("Choose a Directory");

if(compute_overlap == true) run("Grid/Collection stitching", "type=[Grid: snake by rows] order=[Left & Down] grid_size_x="+x_span+" grid_size_y="+y_span+" tile_overlap="+overlap+" first_file_index_i=1 directory=["+dir+"] file_names="+motive_I+".tif output_textfile_name="+tile_config_file+" fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 compute_overlap computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
else run("Grid/Collection stitching", "type=[Grid: snake by rows] order=[Left & Down] grid_size_x="+x_span+" grid_size_y="+y_span+" tile_overlap="+overlap+" first_file_index_i=1 directory=["+dir+"] file_names="+motive_I+".tif output_textfile_name="+tile_config_file+" fusion_method=[Linear Blending] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
saveAs("tiff", dir+"stitched_image_Intensity");
run("Enhance Contrast", "saturated=5");

//Open TileConfiguration file and replace 'I' by 'tau'
tile_config = File.openAsString(dir+"\\"+tile_config_file);
tile_config = replace(tile_config, "I", "tau");
File.saveString(tile_config, dir+"\\"+tile_config_file);
if(compute_overlap == true) {
	last_index_of_dot = lastIndexOf(tile_config_file, ".");
	extension = substring(tile_config_file, last_index_of_dot+1, lengthOf(tile_config_file));
	file_name_without_extension = substring(tile_config_file,0,lengthOf(tile_config_file)-lengthOf(extension)-1);
	tile_config_file_registered = file_name_without_extension+".registered."+extension;
print(tile_config_file_registered);
	tile_config = File.openAsString(dir+"\\"+tile_config_file_registered);
	tile_config = replace(tile_config, "I", "tau");
	File.saveString(tile_config, dir+"\\"+tile_config_file_registered);
}

if(compute_overlap == true) run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=["+dir+"] layout_file="+tile_config_file_registered+" fusion_method=Average regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");
else run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=["+dir+"] layout_file=TileConfiguration.txt fusion_method=Average regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Fuse and display]");

run("Multiply...", "value=1000000000.000");	//Multiply by 10^9 for easy scaling
run("royal");
setMinAndMax(1.5000, 3.5000);
saveAs("tiff", dir+"stitched_image_tau");

selectWindow("stitched_image_Intensity.tif");
run("Copy");
selectWindow("stitched_image_tau.tif");
run("Duplicate...", "title=stitched_image_RGB");
run("RGB Color");
run("HSB Stack");
wait(100);
Stack.setChannel(3);
run("Paste");
run("RGB Color");
