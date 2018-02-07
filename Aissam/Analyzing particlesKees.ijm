// open your image first.
n= roiManager("count");
run("Duplicate...", " ");
run("8-bit");
run("Unsharp Mask...", "radius=1 mask=0.90");
run("Auto Local Threshold", "method=Median radius=15 parameter_1=0 parameter_2=0 white");
setOption("BlackBackground", false);
run("Make Binary");
run("Watershed");
run("Analyze Particles...", "  show=Outlines display exclude add");
// change in the selected window the title to the title of current image.
selectWindow("WT 1.tif");
roiManager("Select", newArray(0,n));
roiManager("Add");