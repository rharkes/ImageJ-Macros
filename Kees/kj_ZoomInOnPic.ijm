rename("A.tif");
getDimensions(width, height, channels, slices, frames);
ratio=width/height;
run("Duplicate...", "title=B.tif");
run("Size...", "width=800 height=800 constrain average interpolation=Bilinear");
saveAs("Tiff", "C:\\Users\\k.jalink\\Desktop\\ffZoom\\B0.tif");
NrOfZooms=200;

for(i=1;i<NrOfZooms;i++){
selectWindow("A.tif");
run("Duplicate...", "title=B.tif");
makeRectangle(10*i, 10*i, width-20*i, height-20*i);	
run("Crop");	
//waitForUser("OK");

wait(3000);
run("Size...", "width=800 height=800 constrain average interpolation=Bilinear");

saveAs("Tiff", "C:\\Users\\k.jalink\\Desktop\\ffZoom\\B"+i+".tif");
close();
}
