// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File suffix", value = ".lif") suffix
// @Boolean(label = "Temporal Median Subtraction", value=true) Bool_TempMed
// @Boolean(label = "Chromatic Abberation Correction", value=true) Bool_ChromCorr
// @String(label = "Filtering String", value = "intensity>500 & sigma>10 & uncertainty<50") filtering_string


/*
 * Macro template to process multiple images in a folder
 * By B.van den Broek, R.Harkes & L.Nahidi
 * 19-06-2018
 * Version 1.2
 * 
 * Changelog
 * 1.1: weighted least squares, threshold to 2*std(Wave.F1)
 * 1.2: error at square brackets, restructure for multi-image .lif, automatic wavelength detection from .lif files
 *      optional chromatic abberation correction enables automatic detection of wavelenth and corresponding affine transformation
 */

photons2adu = 11.71;	//Gain conversion factor of the camera
//These two values will be overwritten if the correct value is found in the .lif file
default_EM_gain=100; 
default_pixel_size=100; 
//
affine_transform_532 = "1.0033870151680693,-3.232761431019966E-4;-3.546907027046711E-4,1.0033518533347512;-26.264283627718463,26.67252580616556";
affine_transform_488 = "1.005381067386475,-1.0666336802334096E-4;-1.0377579033836729E-4,1.0055092526105494;-41.440599081325374,38.65346005022278";
print("---AUTOMATIC THUNDERSTORM---")
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
	inputfile = input + File.separator + file ;
	outputcsv = output + File.separator + substring(file,0, lengthOf(file)-lengthOf(suffix)) + ".csv";	
	outputtiff = output+File.separator+substring(file,0, lengthOf(file)-lengthOf(suffix)) + ".tif";
	print("Processing file "+inputfile);
	if (matches(inputfile,".*[\\[|\\]].*")){ //no square brackets
		print("ERROR: Square brackets in file or foldernames are not supported by ThunderSTORM.");
		exit();
	}
	//open file using Bio-Formats
	run("Bio-Formats Macro Extensions");
	Ext.setId(inputfile);
	Ext.getSeriesCount(nr_series);
	for(n=0;n<nr_series;n++) {
		Ext.setSeries(n);	//numbering apparently starts at 0...
		Ext.getSizeT(sizeT);
		Ext.getSeriesName(seriesName);
		if(sizeT>1) {
			if (nr_series>1){ //feedback & renaming of the outputfiles
				print("Processing file "+inputfile+" ; series "+n+1+"/"+nr_series);
				if(n==0){
					outputcsv_base=substring(outputcsv,0, lengthOf(outputcsv)-lengthOf(suffix));
					outputtiff_base=substring(outputtiff,0, lengthOf(outputtiff)-lengthOf(suffix));
				}
				outputcsv = outputcsv_base + "_series" + n+1 + ".csv";
				outputtiff= outputtiff_base + "_series" + n+1 + ".tif";
			}
			print("Thunderstorm Result in: " + outputcsv);
			run("Close All");
			run("Bio-Formats Importer", "open=[" + inputfile + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+n+1);
			
			EM_gain = default_EM_gain;
			getPixelSize(unit,pixel_size,pixel_size);
			if(unit=="microns"||unit=="micron"||unit=="um"){
				pixel_size = pixel_size*1000;	//set pixel size in nm
			}else if(unit=="pixels") {
				print("Warning: pixel size not found. Assuming 100nm/pixel.");
				pixel_size = default_pixel_size;
			}
			if (endsWith(suffix,"lif")){  //Get info from metadata of the .lif file
				Ext.getSeriesMetadataValue("Image|ATLCameraSettingDefinition|WideFieldChannelConfigurator|WideFieldChannelInfo|FluoCubeName",wavelength); //get wavelength
				if(Bool_ChromCorr&&wavelength!=0) {
					print("Wavelength found in metadata: "+wavelength+" nm");
				}
				Ext.getSeriesMetadataValue("Image|ATLCameraSettingDefinition|EMGainValue",EM_gain); //get EM gain
			}else if (Bool_ChromCorr){
				wavelength = substring(file,lengthOf(file) - lengthOf(suffix) - 3, lengthOf(file) - lengthOf(suffix)); //get wavelength from last three characters of the filename
			}
			processimage(outputtiff, outputcsv, wavelength, EM_gain, pixel_size);
		}
	}	
}

function processimage(outputtiff, outputcsv, wavelength, EM_gain, pixel_size) {
	//Background Subtraction
	if (Bool_TempMed){
		run("Temporal Median Background Subtraction", "window=501 offset=1000");
		run("Camera setup", "offset=1000.0 quantumefficiency=1.0 isemgain=true photons2adu="+photons2adu+" gainem="+EM_gain+" pixelsize="+pixel_size);
	} else {
		run("Camera setup", "offset=100.0 quantumefficiency=1.0 isemgain=true photons2adu="+photons2adu+" gainem="+EM_gain+" pixelsize="+pixel_size);
	}
	
	//Thunderstorm
	run("Run analysis", "filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector=[Local maximum] connectivity=8-neighbourhood threshold=2*std(Wave.F1) estimator=[PSF: Integrated Gaussian] sigma=1.2 fitradius=5 method=[Weighted Least squares] full_image_fitting=false mfaenabled=false renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2 repaint=50");
	run("Export results", "floatprecision=5 filepath=["+ outputcsv + "] fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=false uncertainty_xy=true frame=true");
	
    //Filtering
	if (filtering_string != "") {
		filtering_command = "run(\"Show results table\", \"action=filter formula=[" + filtering_string + "]\")";
		eval(filtering_command);
	}
	saveAs("Tiff", outputtiff);

	//Chromatic Aberration Correction
	if (Bool_ChromCorr){
		print("wavelength = " + wavelength + " nm");
		if (wavelength == "642"){
			affine = "";
		}else if (wavelength == "532") {
			affine = affine_transform_532;
		}else if (wavelength == "488") {
			affine = affine_transform_488;
		}else {
			print("Warning: unknown wavelength ("+wavelength+" nm). No chromatic aberration correction will be applied");
			affine = "";
		}
	
		if (affine!="") {
			run("Close All");
			outputcsv2 = substring(outputcsv,0,lengthOf(outputcsv)-4) + "_chromcorr.csv";
			print("Chromatic Abberation corrected result in: " + outputcsv2);
			run("Do Affine", "csvfile1=["+ outputcsv +"] csvfile2=["+ outputcsv2 + "] affine="+affine);
			run("Import results", "detectmeasurementprotocol=false filepath=["+ outputcsv2 + "] fileformat=[CSV (comma separated)] livepreview=false rawimagestack= startingframe=1 append=false");
			run("Visualization", "imleft=0.0 imtop=0.0 imwidth=180.0 imheight=180.0 renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2 repaint=50");
			outputtiff2 = substring(outputtiff,0,lengthOf(outputtiff)-4) + "_chromcorr.tif";
			saveAs("Tiff", outputtiff2);
		}
	}
}