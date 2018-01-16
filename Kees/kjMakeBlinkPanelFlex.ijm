kjDrempel = 2500;
oldStackName=getTitle;
frameNrs=newArray(100, 300, 1000, 3000, 10000, 30000, 50005, 100000); 

rename("effe.tif");
setSlice(1);
setMinAndMax(0, kjDrempel);
run("Duplicate...", " ");
run("Fire");
run("Canvas Size...", "width=184 height=184 position=Center");
rename("CombinedStrip.tif");
for(i=0; i<8;i++){
selectWindow("effe.tif");
setSlice(frameNrs[i]);
setMinAndMax(0, kjDrempel);
run("Duplicate...", " ");
run("Fire");
run("Canvas Size...", "width=184 height=184 position=Center");
rename("een.tif");
run("Combine...", "stack1=CombinedStrip.tif stack2=een.tif");	
rename("CombinedStrip.tif");
}

rename(oldStackName+"-Selection.tif");
selectWindow("effe.tif");
rename(oldStackName);
