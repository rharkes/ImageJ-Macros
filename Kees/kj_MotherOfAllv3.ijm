/* "the mother of all GFP-PH macro's" implemented in IJ. KJ, nov 2010.
<version: Dec 22 2010> 
<ver: Feb2016 for FIJI>
It assumes that a timelapse stack is open when the macro is fired.
Steps: 1) smooth and threshold to determine cells; 2) close to fill small holes;
3) eat away the outer margin; 4) take a mem-image by eroding memWide and 
subtracting that from the previous one; 5) erode a savety margin; 6) what stays
is cytosol; 7)allow user to mask some parts away; 8) detect and save.
*/
//still to do: create a plugin that does boxcar time smooth with far range
//create a plugin for floodfill
//or find them on the web ************************************************


//helpfunctions***********************************************************************
function kjMessageToLogWindow(txt, kjShow) {
print(txt);
setTool("hand");
selectWindow("Log");
if (kjShow==true){
	print("........click movie to proceed");
 	run("Animation Options...", "start");
	}
}
//************************************************************************************


if (false == File.exists("C:\\ScratchAssayData")) File.makeDirectory("C:\\ScratchAssayData"); 
kjSmooth = 2; // later to be replaced by a keessmooth version
memWide = 5;
kjOuterMargin = 1;
sepWide = 5;
memMean = 0;
cytosolMean = 0;
startFrame = 1;
endFrame = 2; //still implement: set it to max frame default
setFrames = 0;
drawMask = 1;
kjLower = 13;
kjCloseCount = 2;
kjShowIntermediate = true;
StopMaar = true;
kjClose = false;
waitForUser(" KEEP YOUR EYE ON THE DIRECTIONS IN THE Log WINDOW!!!! These guide you through the process.");
print(" KEEP YOUR EYE ON THE DIRECTIONS IN THE Log WINDOW!!!! These guide you through the process.");
selectWindow("Log");
print("select the first image in the image sequence folder.");

do{ 								//makes it cycle through multiple movies
run("Close All");
path = File.openDialog("select the first image in the image sequence folder.");
  dir = File.getParent(path);
  name = File.getName(path);
  print("Name:", name);
  print("Directory:", dir);
  list = getFileList(dir);
  print("Directory contains "+list.length+" files");
run("Image Sequence...", "open=["+path+"]");
run("Set... ", "zoom=50");
rename("InputStack");
setTool("hand");
kjMessageToLogWindow("Adjust parameters in the macro window and press OK", false);

        Dialog.create("Mother of all GFP-PH macros....");				//DIALOG CREATE section
        run("Tile");
        Dialog.addCheckbox("Just this movie", StopMaar); //		<1>NOTE it reads checks and texts in this order!!!!!
        Dialog.addNumber("smoothFactor",kjSmooth); //			<2>
        Dialog.addNumber("outer margin", kjOuterMargin);//		<2A>
        Dialog.addNumber("membrane width", memWide);//			<3>
        Dialog.addNumber("separation width", sepWide);//		<4>
        Dialog.addNumber("Threshold", kjLower);	//			<4B>  THRESHOLD SETTING for cell detection
        Dialog.addCheckbox("Close Mem detected", kjClose);//		<4C>
        Dialog.addNumber("Close cycles",kjCloseCount);//		<4D>      
        Dialog.addCheckbox("setFrames", setFrames);//			<5>
        Dialog.addNumber("startFrame",startFrame);//			<6>
        Dialog.addNumber("endFrame",endFrame); //			<7>
        Dialog.addCheckbox("draw mask", drawMask);//			<8>
        Dialog.addCheckbox("Show Intermediates", kjShowIntermediate); //	<9> This step allows you tuning of individual steps. Disable runs much faster
        Dialog.show;

        StopMaar = Dialog.getCheckbox(); //				<1>DIALOG READOUT section
        kjSmooth=Dialog.getNumber(); //					<2>
        kjOuterMargin=Dialog.getNumber(); //				<2A>
        memWide=Dialog.getNumber(); //				 	<3>
        sepWide=Dialog.getNumber();  //					<4>
        kjLower = Dialog.getNumber(); //				<4B>
        kjClose=Dialog.getCheckbox(); //				<4C>
        kjCloseCount=Dialog.getNumber();//				<4D>
        setFrames=Dialog.getCheckbox(); //				<5>
        if (setFrames==true) startFrame=Dialog.getNumber();//		<6>
        if (setFrames==true) endFrame=Dialog.getNumber(); //		<7>
        drawMask = Dialog.getCheckbox();//				<8>
        kjShowIntermediate = Dialog.getCheckbox(); //			<9>

getDimensions(breed, hoog, kanalen, NrOfSlices, frames);	//alleen NrOfSlices is in gebruik
if (setFrames==true){ //this section will cut out only the slices mentioned in 'setFrames'
selectWindow("InputStack");
if (startFrame >= NrOfSlices) startFrame=1;
if (endFrame > NrOfSlices) endFrame = NrOfSlices;
if (endFrame <= startFrame -1) exit;
run("Duplicate...", "title=Temp duplicate range="+startFrame+"-"+endFrame);
selectWindow("InputStack");
close;
selectWindow("Temp");
rename("InputStack");
}
if (setFrames ==false){
startFrame=1;
endFrame=NrOfSlices;
}
run("Animation Options...", "speed="+12);
if (kjShowIntermediate==true){
	print("--------------------------------------------------");
	print("I am set to show you intermediates. To proceed to each next step, watch the log file messages 'click in the movie' an click once. ");
	print(">>>>>>--------->  DRAG this log window to a place that remaims visible");
	print("--------------------------------------------------");
kjMessageToLogWindow("click movie to proceed", kjShowIntermediate);
	}

for (i=0; i<kjSmooth;i++){
	run("Smooth", "stack");
	print("Data Smoothed"+i);
	}
kjMessageToLogWindow("showing smoothed movie", kjShowIntermediate);
//hier zit normaal een analogue floodfill in******************************************

//run("Threshold...");
setThreshold(kjLower, 255);
run("Threshold...");
selectWindow("Threshold");
waitForUser("adjust upper slider to stain cells red, then press OK but do NOT press apply or set");
getThreshold(kjLower, kjUpper);
print(kjLower);
setThreshold(kjLower, 255);
run("Convert to Mask", "  black");
kjMessageToLogWindow("showing thresholded data", kjShowIntermediate);

if(kjClose==true){
run("Options...", "iterations="+kjCloseCount+" count="+kjCloseCount+" black edm=Overwrite do=Nothing");
run("Close-", "stack");
}
run("Options...", "iterations=1 count=1 black edm=Overwrite do=Nothing");
run("Fill Holes", "stack");
kjMessageToLogWindow("filled holes", kjShowIntermediate);

for (i=0; i<kjOuterMargin; i++){
run("Erode", "stack");
}
rename("Temp");

run("Duplicate...", "title=Cytosol duplicate range=1-4000");
for (i=0; i<memWide; i++){
run("Erode", "stack");
}

imageCalculator("Subtract create stack", "Temp","Cytosol");
rename("Membrane");
selectWindow("Cytosol");
for (i=0; i<sepWide; i++){
run("Erode", "stack");
}
run("Tile");
selectWindow("Cytosol");
kjMessageToLogWindow("membrane eroded by "+memWide, kjShowIntermediate);
selectWindow("Temp");
close;

//now this version is going to be completely different!! overlay three channels:
aantal = 1+endFrame-startFrame;
run("Image Sequence...", "open=["+path+"]"+"number="+aantal+" starting="+startFrame+" increment=1 scale=100 file=[] or=[]");
run("8-bit");
rename("KeesOverlay");

run("Duplicate...", "title=OverlayTemp duplicate range=1-4000");
imageCalculator("AND create stack", "Cytosol","OverlayTemp"); //tot hier ok
rename("OverlayCyto");
selectWindow("Cytosol"); //the next 4 lines make sure there are no zeros in mem: add 1 to it
run("Divide...", "value=256 stack");
imageCalculator("Add create stack", "Cytosol","OverlayCyto");
selectWindow("Result of Cytosol");
rename("OverlayCyto");
run("Tile");

imageCalculator("AND create stack", "Membrane","OverlayTemp");
rename("OverlayMem");
selectWindow("Membrane");
run("Divide...", "value=256 stack");
imageCalculator("Add create stack", "Membrane","OverlayMem");
selectWindow("Result of Membrane");
rename("OverlayMem");
run("Tile");

run("Merge Channels...", "red=OverlayCyto green=KeesOverlay blue=OverlayMem gray=*None* create");
selectWindow("Composite");
rename("KeesOverlay");
selectWindow("KeesOverlay"); 
kjMessageToLogWindow("Overlay of mem, cyto and data...... ", kjShowIntermediate);

do{
selectWindow("KeesOverlay"); 
run("Duplicate...", "title=DrawOverlay duplicate range=1-4000");
if(drawMask==true){
setTool("freehand"); //hier een user interact want deze stap MOET.
waitForUser("create a freehand roi in DrawOverlay covering the section(s) to exclude from analysis....then press OK");
run("Colors...", "foreground=black background=black selection=yellow");
run("Clear", "stack");
}
run("Tile");
selectWindow("DrawOverlay"); 
kjMessageToLogWindow("LastStep", kjShowIntermediate);

selectWindow("DrawOverlay"); 
run("Split Channels");

run("Set Measurements...", "mean redirect=None decimal=3");
selectWindow("C3-DrawOverlay"); 
setThreshold(1, 255);
       for (n=1; n<=nSlices; n++) {
          setSlice(n);
          run("Measure");
      }
selectWindow("C1-DrawOverlay"); 
setThreshold(1, 255);
       for (n=1; n<=nSlices; n++) {
          setSlice(n);
          run("Measure");
      }
effe = getBoolean("Analyze another cell in this stack?");
selectWindow("C1-DrawOverlay"); 
close;
selectWindow("C2-DrawOverlay"); 
close;
selectWindow("C3-DrawOverlay"); 
close;
} 
while(effe); //analyze another cell in this movie
}
while(StopMaar == false);



