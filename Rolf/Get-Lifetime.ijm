// @File(label = "Sample File", style = "file") Sample
// @File(label = "Reference File", style = "file") Reference
// @File(label = "Output File", style = "File") output

/*
 * Macro to calculate lifetime from .fli file
 * Uses fdFLIM plugin. Download at https://github.com/rharkes/fdFLIM/releases
 */

run("Close All");
openfli(Sample,"Sample");
openfli(Reference,"Reference");
run("fdFLIM", "image1=Sample boolphimod=false image2=Reference tau_ref=3.83 freq=40");
saveAs("Tiff", output);

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