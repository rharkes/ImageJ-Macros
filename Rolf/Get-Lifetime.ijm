// @File(label = "Sample File", style = "file") Sample
// @File(label = "Reference File", style = "file") Reference
// @File(label = "Output File", style = "File") output

/*
 * Macro to calculate lifetime from .fli file
 * Uses fdFLIM plugin. Download at https://github.com/rharkes/fdFLIM/releases
 */
Infinity = 1.0/0.0; 
run("Close All");
openfli(Sample,"Sample");
openfli(Reference,"Reference");
run("fdFLIM", "image1=Sample boolphimod=false image2=Reference tau_ref=3.83 freq=40");
setSlice(3);
threshold(0.2);
//saveAs("Tiff", output);

// Open both sample and background from a .fli file and subtract background
function openfli(input,name) {
	run("Bio-Formats", "open=["+input+"] view=Hyperstack stack_order=XYCZT series_1");
	run("32-bit");
	rename(name);
	run("Bio-Formats", "open=["+input+"] view=Hyperstack stack_order=XYCZT series_2");
	run("32-bit");
	rename("BG");
	imageCalculator("Subtract stack", name,"BG");
	selectWindow("BG");
	close();
}

function threshold(thr) {
	run("Set Measurements...", "area mean standard min redirect=None decimal=3");
	List.setMeasurements();
	setThreshold(List.getValue("Max")*thr,Infinity);
	run("Create Mask");
	mask = getTitle;
	run("32-bit");
	run("Divide...", "value=255");
	imageCalculator("Multiply 32-bit stack", "Lifetimes","mask");
}
