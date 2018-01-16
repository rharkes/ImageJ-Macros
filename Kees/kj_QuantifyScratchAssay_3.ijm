/*kj_QuantifyScratchAssay  Kees Jalink, dec 2009, nov 2010 adapted for Nijmegen.
This macro opens a STACK of 8-bit b/w images of a scratch assay.
It detects the open space by image analysis steps and outputs a .xls file that
can be opened in excel. User needs to graph the mean intensity column versus frameNr himself.
This allows maximum flexibility in how you want the graph.
The outputfile is placed in folder C:\ScratchAssayData which is created if it doesn't exist. 
A unique filename for the excel data is automatically picked.
Note the scale: 0 is no cells detected in image, 255 is fully closed gap (so, 255 = 100%).

So: 
>>Run this macro; optionally set some parameters
>>Open the output file <C:\SratchAssayData\##UniqueName##.xls > in excel and make a scattergraph.
>>Save the excel file under a meaningful name in the same folder as the data for convenience

DIALOG INPUTs:
<1> Check this if you don't want multiple analysis
<2> FRAMERATE of the movies; default 12
<3> DEGREE OF PRE-SMOOTHING of the pics; typically 2 for 512 x 512 movies
<4> DEGREE OF DILATION, which closes small holes in the monolayer; typically 5-15
<4A>  RADIUS of the variance filter. The var determines where cells are because cells contain more dark/bright variations; typ 4-15
<4B>  THRESHOLD SETTING for cell detection; typ 10-50
<5> Only necessary in case of severe shading differences. This unshades but it is a slow step
<6> This step allows you tuning of individual steps. Disable runs much faster

*/
if (false == File.exists("C:\\ScratchAssayData")) File.makeDirectory("C:\\ScratchAssayData"); 
first_time = true;
kjSmooth = 2;
kjDilate = 3;
kjVariance = 8;
kjLower= 90;
kjShowIntermediate = true;
kjFrameRate = 12;
kjSubtractBkgr = false;
waitForUser(" KEEP YOUR EYE ON THE DIRECTIONS IN THE Log WINDOW!!!! These guide you through the process.");
print(" KEEP YOUR EYE ON THE DIRECTIONS IN THE Log WINDOW!!!! These guide you through the process.");
selectWindow("Log");
print("select the first image in the image sequence folder.");

run("Set Measurements...", "area mean standard min centroid area_fraction redirect=None decimal=3");
run("Close All");
run("Clear Results");

do{ 								//makes it cycle through multiple movies
path = File.openDialog("select a movie to analyze");
  dir = File.getParent(path);
  name = File.getName(path);
  print("Name:", name);
  print("Directory:", dir);
  list = getFileList(dir);
  print("Directory contains "+list.length+" files");
open(path);
getDimensions(width, height, channels, slices, frames);
if(slices>frames && frames==1) {
	run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");
	run("Hyperstack to Stack");
	getDimensions(width, height, channels, slices, frames);
}
run("Grays");
movie = getTitle();

selectWindow("Log");

print("Adjust parameters in the macro window and press OK");

   Dialog.create("kj_QuantifyScratchAssay");			//DIALOG CREATE section
//   Dialog.addCheckbox("Just this movie", StopMaar); //	<1>NOTE it reads checks and texts in this order!!!!!
   Dialog.addNumber("FrameRate",kjFrameRate); //		<2> FRAMERATE of the movies
   Dialog.addNumber("Smooth", kjSmooth); //			<3> DEGREE OF PRE-SMOOTHING of the pics
   Dialog.addNumber("Dilate", kjDilate); //			<4> DEGREE OF DILATION, which closes small holes in the monolayer
   Dialog.addNumber("Variance Radius", kjVariance);	//	<4A>  RADIUS of the variance filter. The var determines where cells are because cells contain more dark/bright variations
   Dialog.addNumber("Threshold", kjLower);	//		<4B>  THRESHOLD SETTING for cell detection
   Dialog.addMessage("(in case of severe shading)");
   Dialog.addCheckbox("subtract Background",kjSubtractBkgr) //	<5> Only necessary in case of severe shading differences
   Dialog.addCheckbox("Show Intermediates", kjShowIntermediate); //	<6> This step allows you tuning of individual steps. Disable runs much faster
   Dialog.show;

//   StopMaar = Dialog.getCheckbox(); //			<1>DIALOG READOUT section
   kjFrameRate=Dialog.getNumber(); //			<2>
   kjSmooth=Dialog.getNumber(); //				<3>
   kjDilate=Dialog.getNumber(); //				<4>
   kjVariance = Dialog.getNumber(); //				<4A>
   kjLower = Dialog.getNumber(); //				<4B>
   kjSubtractBkgr = Dialog.getCheckbox(); //			<5>
   kjShowIntermediate = Dialog.getCheckbox(); //		<6>

run("Animation Options...", "speed="+kjFrameRate);
if (kjShowIntermediate==true){
	print("I am set to show you intermediates. To proceed to the next step, close this message with OK then click in the movie once. ");
	print("........click movie to proceed");
	selectWindow("Log");

	run("Animation Options...", "start");
	}

//for (i=0; i<kjSmooth;i++){
//	run("Smooth", "stack");
	if(kjSmooth>0) run("Mean...", "radius="+kjSmooth+" stack");
	print("Data Smoothed");
//	}
	
selectWindow("Log");

if (kjShowIntermediate==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}
	
if (kjSubtractBkgr==true){
	print("subtracting background. This is a slow step.");
	run("Subtract Background...", "rolling=25 stack");
	print("Data Bkgr subtracted");
	selectWindow("Log");

if (kjShowIntermediate==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}
}

run("Variance...", "radius="+kjVariance+" stack");
print("Variance determined");
selectWindow("Log");

if (kjShowIntermediate==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}

run("Threshold...");
setThreshold(kjLower, 255);
setAutoThreshold("Default dark stack");
waitForUser("adjust upper slider to stain cells red, then press OK but do NOT press apply or set");
getThreshold(kjLower, kjUpper);
print(kjLower);
setThreshold(kjLower, 255);
run("Convert to Mask", "  black");
print("Data thresholded");
selectWindow("Log");

if (kjShowIntermediate==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}

run("Options...", "iterations="+kjDilate+" count=1 black edm=Overwrite");
run("Dilate", "stack");
print("Data Binary Dilated");
selectWindow("Log");

if (kjShowIntermediate==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}

kjTime=getTime();
run("Measure"); //makes sure the resultswindow exists before I close it
selectWindow("Results");
run ("Close");
selectWindow(movie);
Area_perc = newArray(frames);
for(f=0;f<frames;f++) {
	Stack.setFrame(f+1);
	run("Measure");
	Area_perc[f] = getResult("%Area");
}

Plot.create("Scratch Assay Plot: "+name, "time", "Percentage covered");	//create an empty plot
Plot.setFrameSize(800, 450);
Plot.setLineWidth(2);
Plot.setColor("red");
Plot.add("line", Area_perc);
Plot.setLimitsToFit();
//Plot.getLimits(xMin, xMax, yMin, yMax);
Plot.setLimits(1, NaN, 0, 105);
Plot.show();

saveAs("Results", dir+"\\"+name+"_results_"+kjTime+".xls");
print("Data saved as "+dir+"\\"+name+"_results_"+kjTime+".xls");
selectWindow("Log");
print(" ");
print("------------------------------------");
print(" ");

waitForUser("Press OK to continue");

another_one = getBoolean("Do you want to analyze another movie?");
if(random<0.1) exit("You belong to the unlucky 10%. Exiting macro.");

close(name);
} 								// end of do-loop
while (another_one==true);
