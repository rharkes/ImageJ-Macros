// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File suffix", value = ".lif") suffix
// @Boolean(label = "Temporal Median Subtraction", value=true) Bool_TempMed
// @String(label = "Filtering String", value = "intensity>500 & sigma>10 & uncertainty<50") filtering_string


/*
 * Macro template to process multiple images in a folder
 * By R.Harkes & L.Nahidi (c) GPLv3 2018
 * 10-01-2018
 * Version 1.1
 * 
 * Changelog
 * 1.1: weighted least squares (and some other updates)
 */

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
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
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	inputfile = input + File.separator + file ;
	outputcsv = "[" + output + File.separator + substring(file,0, lengthOf(file)-lengthOf(suffix)) + ".csv"+"]" ;
	print("Processing: " + inputfile);
	print("Thunderstorm Result in: " + outputcsv);
	//open file using Bio-Formats
	run("Close All");
	run("Bio-Formats Macro Extensions");
	Ext.setId(inputfile);
	run("Bio-Formats Importer", "open=&inputfile autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_1");

	//Background Subtraction
	if (Bool_TempMed){
		run("Temporal Median Background Subtraction", "window=501 offset=1000");
	}
	
	//Thunderstorm
	run("Run analysis", "filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector=[Local maximum] connectivity=8-neighbourhood threshold=2*std(Wave.F1) estimator=[PSF: Integrated Gaussian] sigma=1.2 fitradius=5 method=[Weighted Least squares] full_image_fitting=false mfaenabled=false renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2 repaint=50");
	run("Export results", "floatprecision=5 filepath="+ outputcsv + " fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=false uncertainty_xy=true frame=true");
	outputtiff = output+File.separator+substring(file,0, lengthOf(file)-lengthOf(suffix)) + ".tif";
	saveAs("Tiff", outputtiff);

	//Filtering
	if (filtering_string != "") {
		filtering_command = "run(\"Show results table\", \"action=filter formula=[" + filtering_string + "]\")";
		eval(filtering_command);
	}

	//Chromatic Aberration Correction
	wavelength = substring(file,lengthOf(file) - lengthOf(suffix) - 3, lengthOf(file) - lengthOf(suffix));
	print("wavelength = " + wavelength + "nm");
	if (wavelength == "647") {
		affine = "";
	} else if (wavelength == "532") {
		affine = "1.0033870151680693,-3.232761431019966E-4;-3.546907027046711E-4,1.0033518533347512;-26.264283627718463,26.67252580616556";
	} else if (wavelength == "488") {
		affine = "1.005381067386475,-1.0666336802334096E-4;-1.0377579033836729E-4,1.0055092526105494;-41.440599081325374,38.65346005022278";
	} else {
		affine = "";
	}

	if (affine!="") {
		run("Close All");
		outputcsv2 = "[" + output + File.separator + substring(file,0, lengthOf(file) - lengthOf(suffix)) + "_chromcorr.csv"+"]";
		print("Chromatic Abberation corrected result in: " + outputcsv2);
		run("Do Affine", "csvfile1="+ outputcsv +" csvfile2="+ outputcsv2 + " affine="+affine);
		run("Import results", "detectmeasurementprotocol=false filepath="+ outputcsv2 + " fileformat=[CSV (comma separated)] livepreview=false rawimagestack= startingframe=1 append=false");
		run("Visualization", "imleft=0.0 imtop=0.0 imwidth=180.0 imheight=180.0 renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2");
		outputtiff2 = output + File.separator + substring(file,0, lengthOf(file)-lengthOf(suffix)) + "_chromcorr.tif";
		saveAs("Tiff", outputtiff2);
	}
}
