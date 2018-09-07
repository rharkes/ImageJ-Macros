@File(label = "Input directory", style = "directory") input
@File(label = "Output directory", style = "directory") output
@String(label = "File suffix", value = ".lif") suffix
@Boolean(label = "Temporal Median Subtraction", value=true) Bool_TempMed
@Boolean(label = "Chromatic Abberation Correction", value=true) Bool_ChromCorr
@Boolean(label = "Automatic Merging", value=true) Bool_AutoMerge
@String(label = "Filtering String", value = "intensity>500 & sigma>70 & uncertainty_xy<50") filtering_string


/*
 * Macro template to process multiple images in a folder
 * By B.van den Broek, R.Harkes & L.Nahidi
 * 23-08-2018
<<<<<<< HEAD
 * Version 1.32
=======
 * Version 1.31
>>>>>>> origin/master
 * 
 * Changelog
 * 1.1: weighted least squares, threshold to 2*std(Wave.F1)
 * 1.2: error at square brackets, restructure for multi-image .lif, automatic wavelength detection from .lif files
 *      optional chromatic abberation correction enables automatic detection of wavelenth and corresponding affine transformation
 * 1.3: Save Settings to .JSON file    
 * 1.31: Added automatic merging
<<<<<<< HEAD
 * 1.32: Fixed a bug concerning chromatic aberration (crash ifit was not applied)
=======
>>>>>>> origin/master
 */
Version = 1.3;
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
	outputtiff = output+File.separator+substring(file,0, lengthOf(file)-lengthOf(suffix)) + "_TS.tif";
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
		Ext.getSizeZ(sizeZ);
		Ext.getSeriesName(seriesName);
		
		if((sizeT>1) || (sizeZ>1&&suffix==".tif")) {
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
	offset = 1000;
	window = 501;
	if (Bool_TempMed){
		run("Temporal Median Background Subtraction", "window="+window+" offset="+offset);
	} else {
		offset=100;
	}
	//Camera Setup
	readoutnoise=0;
	quantumefficiency=1;
	isemgain=true;
	run("Camera setup", "readoutnoise="+readoutnoise+" offset="+offset+" quantumefficiency="+quantumefficiency+" isemgain="+isemgain+" photons2adu="+photons2adu+" gainem="+EM_gain+" pixelsize="+pixel_size);
	
	//Thunderstorm
	ts_filter = "Wavelet filter (B-Spline)";
	ts_scale = 2;
	ts_order = 3;
	ts_detector = "Local maximum";
	ts_connectivity = "8-neighbourhood";
	ts_threshold = "2*std(Wave.F1)";
	ts_estimator = "PSF: Integrated Gaussian";
	ts_sigma = 1.2;
	ts_fitradius = 5;
	ts_method = "Weighted Least squares";
	ts_full_image_fitting = false;
	ts_mfaenabled = false;
	ts_renderer = "Averaged shifted histograms";
	ts_magnification = 10;
	ts_colorize = false;
	ts_threed = false;
	ts_shifts = 2;
	ts_repaint = 50;
	ts_floatprecision = 5;
<<<<<<< HEAD
	affine = "";
=======
>>>>>>> origin/master
	run("Run analysis", "filter=["+ts_filter+"] scale="+ts_scale+" order="+ts_order+" detector=["+ts_detector+"] connectivity=["+ts_connectivity+"] threshold=["+ts_threshold+
	  "] estimator=["+ts_estimator+"] sigma="+ts_sigma+" fitradius="+ts_fitradius+" method=["+ts_method+"] full_image_fitting="+ts_full_image_fitting+" mfaenabled="+ts_mfaenabled+
	  " renderer=["+ts_renderer+"] magnification="+ts_magnification+" colorize="+ts_colorize+" threed="+ts_threed+" shifts="+ts_shifts+" repaint="+ts_repaint);
	run("Export results", "floatprecision="+ts_floatprecision+" filepath=["+ outputcsv + "] fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=true uncertainty_xy=true frame=true");

	//Automatic Merging
	AutoMerge_ZCoordWeight=0.1;
	AutoMerge_OffFrame=1;
	AutoMerge_Dist=20;
	AutoMerge_FramesPerMolecule=0;
	if (Bool_AutoMerge) {
		run("Show results table", "action=merge zcoordweight="+AutoMerge_ZCoordWeight+" offframes="+AutoMerge_OffFrame+" dist="+AutoMerge_Dist+" framespermolecule="+AutoMerge_FramesPerMolecule);
	}
	
    //Filtering
	if (filtering_string != "") {
		run("Show results table", "action=filter formula=[" + filtering_string + "]");
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
			wavelength=0;
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

	//save the settings (Trying to stick to JSON for this)
	jsonfile = substring(outputcsv,0,lengthOf(outputcsv)-4) + "_TS.json";
	File.delete(jsonfile)
	f = File.open(jsonfile);
	print(f, "{\"Super Resolution Post Processing Settings\": {");
	print(f, "  \"Version\" : \""+Version+"\",");
	print(f, "  \"Date\" : \""+getDateTime()+"\",");
	print(f, "  \"File\" : \""+file+"\",");
	print(f, "  \"File Location\" : \""+input+"\",");
	print(f, "  \"Temporal Median Filtering\" : {");
	print(f, "    \"Applied\" : "+makeBool(Bool_ChromCorr)+",");
	print(f, "    \"window\" : "+window+",");
	print(f, "    \"offset\" : "+offset);
	print(f, "   },");
	print(f, "  \"ThunderStorm Settings\" : {");
	print(f, "  \"Camera Settings\" : {");
	print(f, "    \"offset\" : "+offset+",");
	print(f, "    \"quantumefficiency\" : "+quantumefficiency+",");
	print(f, "    \"emgain\" : "+makeBool(isemgain)+",");
	print(f, "    \"readoutnoise\" : "+readoutnoise+",");
	print(f, "    \"photons2adu\" : "+photons2adu+",");
	print(f, "    \"emgain level\" : "+EM_gain+",");
	print(f, "    \"pixelsize\" : "+pixel_size);
	print(f, "   },");
	print(f, "  \"Image filtering\" : {");
	print(f, "    \"filter\" : \""+ts_filter+"\",");
	print(f, "    \"scale\" : "+ts_scale+",");
	print(f, "    \"order\" : "+ts_order);
	print(f, "   },");
	print(f, "  \"Approximate localization of molecules\" : {");
	print(f, "    \"detector\" : \""+ts_detector+"\",");
	print(f, "    \"connectivity\" : \""+ts_connectivity+"\",");
	print(f, "    \"threshold\" : \""+ts_threshold+"\"");
	print(f, "   },");
	print(f, "  \"Sub-pixel localization of molecules\" : {");
	print(f, "    \"estimator\" : \""+ts_estimator+"\",");
	print(f, "    \"sigma\" : "+ts_sigma+",");
	print(f, "    \"fitradius\" : "+ts_fitradius+",");
	print(f, "    \"method\" : \""+ts_method+"\",");
	print(f, "    \"full image fitting\" : "+makeBool(ts_full_image_fitting)+",");
	print(f, "    \"multi-emitter fitting analysis enabled\" : "+makeBool(ts_mfaenabled));
	print(f, "   },");
	print(f, "  \"Visualization of the results\" : {");
	print(f, "    \"renderer\" : \""+ts_renderer+"\",");
	print(f, "    \"magnification\" : "+ts_magnification+",");
	print(f, "    \"colorize\" : "+makeBool(ts_colorize)+",");
	print(f, "    \"Three Dimensional\" : "+makeBool(ts_threed)+",");
	print(f, "    \"Lateral shifts\" : "+ts_shifts+",");
	print(f, "    \"Update Frequency\" : "+ts_repaint);
	print(f, "   },");
	print(f, "  \"Output\" : {");
	print(f, "    \"csv float precision\" : "+ts_floatprecision);
	print(f, "   }");
	print(f, "   },");
	print(f, "  \"Filtering\" :{");
	print(f, "    \"Filtering string\" : \""+filtering_string+"\"");
	print(f, "   },");
	print(f, "  \"Automatic Merging\" :{");
	print(f, "    \"Applied\" : "+makeBool(Bool_AutoMerge)+",");
	print(f, "    \"Z coordinate weight\" : "+AutoMerge_ZCoordWeight+",");
	print(f, "    \"Maximum off frames\" : "+AutoMerge_OffFrame+",");
	print(f, "    \"Maximum distance\" : "+AutoMerge_Dist+",");
	print(f, "    \"Maximum frames per molecule\" : "+AutoMerge_FramesPerMolecule);
	print(f, "   },");
	print(f, "  \"Chromatic Abberation Correction\" :{");
	print(f, "    \"Requested\" : "+makeBool(Bool_ChromCorr)+",");
	print(f, "    \"Applied\" : "+makeBool((affine!=""))+",");
	print(f, "    \"Wavelength\" : "+ wavelength+",");
	print(f, "    \"Applied Affine Transform\" : ["+replace(affine, ";", ",")+"]");
	print(f, "   }");
	print(f, "}}");
	File.close(f)
}	

function makeBool(in) {
	if(in){
		in="true";
	}else{
		in="false";
	}
	return in;
}


function getDateTime() {
     MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
     DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
     getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
     TimeString =DayNames[dayOfWeek]+" ";
     if (dayOfMonth<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+" @ ";
     if (hour<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+hour+":";
     if (minute<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+minute+":";
     if (second<10) {TimeString = TimeString+"0";}
     TimeString = TimeString+second;
     return TimeString;
<<<<<<< HEAD
}
=======
  }
>>>>>>> origin/master
