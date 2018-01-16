//Kees test macro for filterFRET ----------- KJ 11/08
//This is the second version that includes masking od pixels to calculate the corrfactors,
//FRET efficiency and cleanup routines
//NOTE it needs the files donor, sens and acceptor in c:\\dataff
//-----------SECTION: PREPARE
var alfa, beta, gamma, delta, a, b, c, d, e, f, g, h, i, j, A, S, D, DonBKG, SensBKG, AccBKG;
run("Close All");
open("C:\\dataff\\Donor.tif");
run("32-bit");
run("Out");
run("Out");
run("Fire")
run("Threshold..."); //to make sure the window exists
open("C:\\dataff\\Sens.tif");
run("32-bit");
run("Out");
run("Out");
run("Fire")
open("C:\\dataff\\Acceptor.tif");
run("32-bit");
run("Out");
run("Out");
run("Fire")
run("Tile");

//Set up some windows............
print("test", 0); //makes sure a log window exists to avoid errors when closing it
selectWindow("Log");
run("Close");
run("Measure"); //makes sure a results window exists
selectWindow("Results");
run("Clear Results");
run("ROI Manager..."); //makes Window("ROI Manager");
selectWindow("ROI Manager");
run("Close");//by closing it, it is emptied
run("ROI Manager..."); //now we have an empty one

//---------SECTION: PRETREAT IMAGES
selectWindow("Donor.tif");
run("Smooth");
selectWindow("Sens.tif");
run("Smooth");
selectWindow("Acceptor.tif");
run("Smooth");

//-------SECTION: subtract im background
//waitForUser("CHOOSE", "Subtract Background From Images?"); //hier: keus inbouwen
run("Duplicate...", "title=10PlusAcceptor.tif");
run("Add...", "value=10"); //makes sure not to much 'divide-by-0' happens
imageCalculator("Divide create 32-bit", "Donor.tif","10PlusAcceptor.tif");
rename("DonDivBy10PlusAcc.tif");
waitForUser("INPUT", "Draw Roi for donor background");
roiManager("add"); //will be roi 0
selectWindow("10PlusAcceptor.tif");
close;

selectWindow("Donor.tif"); 
roiManager("select", 0);
run("Measure");
DonBKG=getResult("Mean",0);
selectWindow("Donor.tif");
ff = "value=" + DonBKG;
run("Select None");
run("Subtract...", ff);
print("DonorBkg", DonBKG);

selectWindow("Sens.tif");
roiManager("select", 0);
run("Measure");
SensBKG =getResult("Mean",1);
ff = "value=" + SensBKG;
run("Select None");
run("Subtract...", ff);
print("SensBkg", SensBKG);

selectWindow("Acceptor.tif");
roiManager("select", 0);
run("Measure");
AccBKG =getResult("Mean",2);
ff="value=" + AccBKG;
run("Select None");
run("Subtract...", ff);
print("AcceptorBkg", AccBKG);

//---------SECTION: pixelmasking for corrfacs
//1. indicate roi for ref cell
//2. wipe out all image except for roi (ROI: invert; fill or clear)
//3. set threshold; make mask
//4. edit-selection-create levert de ROI
selectWindow("DonDivBy10PlusAcc.tif");
roiManager("Deselect");
setThreshold(1.5, 10000);
selectWindow("Threshold");
waitForUser("INPUT", "Set Threshold and Draw Roi for Donor Cell");
run("Make Inverse");
run("Set...", "value=0");
run("Create Selection");
roiManager("add"); //will be roi 1
run("Out");
run("Out");

selectWindow("Donor.tif");
run("Duplicate...", "title=10PlusDonor.tif");
run("Add...", "value=10"); //makes sure not to much 'divide-by-0' happens
imageCalculator("Divide create 32-bit", "Acceptor.tif","10PlusDonor.tif");
rename("AccDivBy10PlusDon.tif");
selectWindow("10PlusDonor.tif");
close;
selectWindow("AccDivBy10PlusDon.tif");
setThreshold(2, 10000);
selectWindow("Threshold");//<---------- must be made correct yet
waitForUser("INPUT", "Set Threshold and Draw Roi for Acceptor Cell");
run("Make Inverse");
run("Set...", "value=0");
run("Create Selection");
roiManager("add"); //will be roi 2
run("Out");
run("Out");
run("Tile");

//---------SECTION: MEASURE IN ROIS
selectWindow("Donor.tif"); //FIRST for Beta
roiManager("select", 1);
run("Measure");
a=getResult("Mean",3);
selectWindow("Sens.tif");
roiManager("select", 1);
run("Measure");
c=getResult("Mean",4);
beta=c/a;
print("beta", beta); // into the log window

selectWindow("Acceptor.tif"); //NOW for the acceptor cell values
roiManager("select", 2);
run("Measure");
A=getResult("Mean",5); 
selectWindow("Sens.tif");
roiManager("select", 2);
run("Measure");
S=getResult("Mean",6);
selectWindow("Donor.tif");
roiManager("select", 2);
run("Measure");
D=getResult("Mean",7);

gamma=S/A;
print("gamma",gamma);
delta=D/S;
print("delta",delta);
alpha=D/A;
print("alpha",alpha);

//-------SECTION: CORRECT IMAGES
EenMinBetaDelta = 1-beta*delta;
print("1-bd",EenMinBetaDelta);
GammaMinAlphaBeta=gamma - alpha*beta;
print("g-ab",GammaMinAlphaBeta );
selectWindow("Donor.tif");
run("Select None");
run("Duplicate...", "title=betaDonor.tif");
run("Out");
run("Out");
ff="value="+beta;
selectWindow("betaDonor.tif");
run("Multiply...", ff);

selectWindow("Acceptor.tif");
run("Select None");
run("Duplicate...", "title=corrAcceptor.tif");
run("Out");
run("Out");
selectWindow("corrAcceptor.tif");
ff="value="+GammaMinAlphaBeta;
run("Multiply...", ff);
imageCalculator("Subtract create 32-bit", "Sens.tif","betaDonor.tif");
selectWindow("Result of Sens.tif");
imageCalculator("Subtract create 32-bit", "Result of Sens.tif","corrAcceptor.tif");
ff="value="+EenMinBetaDelta;
run("Multiply...",ff );

selectWindow("Result of Sens.tif");
close();
selectWindow("corrAcceptor.tif");
close();
selectWindow("betaDonor.tif");
close();
selectWindow("AccDivBy10PlusDon.tif");
close();
selectWindow("DonDivBy10PlusAcc.tif");
close();
selectWindow("Result of Result of Sens.tif");
run("Duplicate...", "title=SE.tif");
selectWindow("Result of Result of Sens.tif");
setOption("Show All",true);
run("Tile");
run("Histogram", "bins=256 use x_min=-10 x_max=255 y_max=Auto");



//exit;



//---------SECTION: FRET EFFICIENCY
selectWindow("SE.tif");
run("Duplicate...","title=Ea.tif");
run("Duplicate...","title=Ed.tif");
imageCalculator("Divide create 32-bit", "Ed.tif","Donor.tif");
setMinAndMax(-0.5, 1.5);
imageCalculator("Divide create 32-bit", "Ea.tif","Acceptor.tif");
setMinAndMax(0.5, 1.5);
selectWindow("Ea.tif");
close();
selectWindow("Ed.tif");
close();

//---------SECTION: CLEANUP
imageCalculator("Add create 32-bit", "Donor.tif","Acceptor.tif");//mask based on D+A
rename("mask.tif");
setThreshold(15, 512);
run("Make Binary");
run("Convert to Mask");
setMinAndMax(-1, 1);
run("Out");
run("Out");
//selectWindow("Histogram of SE");
//close();
//run("Tile");

run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit", "mask.tif","Result of Ea.tif");
rename("MaskedEa.tif");
run("Brightness/Contrast...");
setMinAndMax(-0.5, 1.5);
run("Fire");
imageCalculator("Multiply create 32-bit", "mask.tif","Result of Ed.tif");
rename("MaskedEd.tif");
run("Brightness/Contrast...");
setMinAndMax(-0.5, 1.5);
run("Fire");
//-------------------------------------------------KLAAR------------------------------------------------------------->>>>
//future to add: panel for file-input including 'setje' and batch;
//mixFretIntensity; analysis of ROIs; 
//
exit; 







//hereafter: dump place-------------------------------------------------------------

// "Close All Windows"
// This macro closes all image windows.
// Add it to the StartupMacros file to create
// a "Close All Windows" command, or drop it
// in the ImageJ/plugins/Macros folder.
// Note that some ImageJ 1.37 has a bug that
// causes this macro to run very slowly.

  macro "Close All Windows" { 
      while (nImages>0) {
          selectImage(nImages);
          close(); 
      } 
  } 


// This macro demonstrates how do use the 
// File.openDialog() macro function.

  path = File.openDialog("Select a File");
  //open(path); // open the file
  dir = File.getParent(path);
  name = File.getName(path);
  print("Path:", path);
  print("Name:", name);
  print("Directory:", dir);
  list = getFileList(dir);
  print("Directory contains "+list.length+" files");

