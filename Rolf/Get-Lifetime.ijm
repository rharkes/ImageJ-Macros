// @File(label = "Sample File", style = "file") Sample
// @File(label = "Reference File", style = "file") Reference
// @File(label = "Output Directory", style = "directory") output

/*
 * Macro to calculate lifetime from .fli file
 * Uses fdFLIM plugin. Download at https://github.com/rharkes/fdFLIM/releases
 */
 
phases = 12;
tau_ref = 3.93;
freq = 40;

run("Close All");
setBatchMode(true);
openfli(Reference,"Reference");
openfli(Sample,"Sample");
getDimensions(w, h, channels, slices, frames);
// loop over all frames
for (i = 0; i < (frames/phases); i++) {
	selectWindow("Sample");
	if (i<((frames/phases)-1)){ //last frame
		run("Make Substack...", "delete slices=1-12");
	}
	rename("temp_img");
	run("fdFLIM", "image1=[temp_img] boolphimod=false image2=Reference tau_ref="+tau_ref+" freq="+freq);	
	selectWindow("temp_img");
	close();
	if (i==0){
		rename("Lifetimes_final");
	}else{
		run("Concatenate...", "  title=Lifetimes_final open image1=Lifetimes_final image2=Lifetimes");
	}	
}
selectWindow("Reference");
close();
setBatchMode("show");
setMinAndMax(1, 4);
run("physics");
Sample = split(Sample,File.separator);
Sample = Sample[Sample.length-1];
print(Sample);
saveAs("Tiff", output + File.separator + substring(Sample,0, lengthOf(Sample)-3) + "tif");

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
