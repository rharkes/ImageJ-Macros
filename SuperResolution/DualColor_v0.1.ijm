// @File(label = "Input directory", style = "directory") input
// @File(label = "Output directory", style = "directory") output
// @String(label = "File suffix", value = ".lif") suffix
// @Boolean(label = "Temporal Median Subtraction", value=true) Bool_TempMed


/*
 * Macro template to process dual-color  GSDIM .lif images in a folder
 * By R.Harkes & L.Nahidi (c) GPLv3 2018
 * 10-01-2018
 * Version 1.0
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
    print("Processing: " + inputfile);
    
    //Left and right seperate Thunderstorm: Split data
    for (i = 0; i<2 ; i++) {
    	//open file using Bio-Formats
        run("Close All");
        run("Bio-Formats Macro Extensions");
        Ext.setId(inputfile);
        run("Bio-Formats Importer", "open=&inputfile autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_1");
        width = getWidth;
        height = getHeight;
        if (i==0) {
        	outputcsv = "[" + output + File.separator + substring(file,0, lengthOf(file)-lengthOf(suffix)) + "_L.csv"+"]" ;
        	outputtiff = output+File.separator+substring(file,0, lengthOf(file)-lengthOf(suffix)) + "L.tif";
    	    makeRectangle(0, 0, width/2, height);
        }
        if (i==1) {
        	outputcsv = "[" + output + File.separator + substring(file,0, lengthOf(file)-lengthOf(suffix)) + "_R.csv"+"]" ;
        	outputtiff = output+File.separator+substring(file,0, lengthOf(file)-lengthOf(suffix)) + "_R.tif";
    	    makeRectangle(width/2, 0, width/2, height);
        }
        run("Crop");
        print("Thunderstorm Result in: " + outputcsv);
    
        //Background Subtraction
        if (Bool_TempMed){
            run("Temporal Median Background Subtraction", "window=501 offset=1000");
        }

        //Thunderstorm
        run("Run analysis", "filter=[Wavelet filter (B-Spline)] scale=2.0 order=3 detector=[Local maximum] connectivity=8-neighbourhood threshold=std(Wave.F1) estimator=[PSF: Integrated Gaussian] sigma=1.2 fitradius=3 method=[Maximum likelihood] full_image_fitting=false mfaenabled=false renderer=[Averaged shifted histograms] magnification=10.0 colorize=false threed=false shifts=2 repaint=50");
        run("Export results", "floatprecision=5 filepath="+ outputcsv + " fileformat=[CSV (comma separated)] sigma=true intensity=true offset=true saveprotocol=false x=true y=true bkgstd=true id=false uncertainty_xy=true frame=true");
    
        saveAs("Tiff", outputtiff);
    }
 }