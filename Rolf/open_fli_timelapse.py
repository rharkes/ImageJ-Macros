# @File ReferenceFile
# @File SampleFile

#import BioFormats
from loci.plugins import BF
from loci.plugins.in import ImporterOptions
#import Image Calculator for background subtraction
from ij.plugin import 
#some ij functionality
from ij import IJ 
from ij.plugin import HyperStackConverter
from ij.process import AutoThresholder
from ij import ImagePlus
from ij import WindowManager
from ij.process.AutoThresholder.Method import Otsu

# It's best practice to create a function that contains the code that is executed when running the script.
# This enables us to stop the script by just calling return.
def run_script():
	SamIm = open_fli(SampleFile.getAbsolutePath())
	SamIm.show()
	RefIm = open_fli(ReferenceFile.getAbsolutePath())
	RefIm.show()
	reftau = RefIm.getStringProperty("PARAMETERS: ACQUISITION SETTINGS - RefLifetime")
	freq = SamIm.getStringProperty("PARAMETERS: ACQUISITION SETTINGS - Frequency")
	IJ.run("fdFLIM", "image1=["+SamIm.getTitle()+"] boolphimod=false image2=["+RefIm.getTitle()+"] tau_ref="+reftau+" freq="+freq);
	SamIm.close()
	RefIm.close()
	#Stack to Hyperstack
	result1 = IJ.getImage()
	result = HyperStackConverter.toHyperStack(result1,3,1,1,"xyctz","grayscale")
	result1.close()
	#set to NaN
	set_to_nan(result)	
	#set range and LUT
	set_range_LUT(result,1,1,4,"Royal")
	set_range_LUT(result,2,1,4,"Royal")
	set_range_LUT(result,3,-1E11,1E11,"Grays")
	result.show()

def set_to_nan(img):
	img.show()
	img.setC(3)
	meanintensity = img.getProcessor()
	meanintensity.setAutoThreshold(Otsu, 1) 
	IJ.run("Create Selection")
	IJ.run("Make Inverse")
	img.setC(2)
	IJ.run("Set...", "value=NaN")
	img.setC(1)
	IJ.run("Set...", "value=NaN")
	IJ.run("Select None")
	
def set_range_LUT(img,channel,minval,maxval,lut):
	img.setC(channel)
	if abs(minval)>1E10 or abs(maxval)>1E10:
		stats=img.getStatistics()
		minval=stats.min
		maxval=stats.max
	img.setDisplayRange(minval,maxval)
	img.show()
	IJ.run(lut)

def open_fli(filepth):
	# load the dataset
	options = ImporterOptions()
	options.setId(filepth)
	options.setOpenAllSeries(1)
	imps = BF.openImagePlus(options)
	for imp in imps:
		title = imp.getTitle()
		if title.find("Background Image")==-1:
			img = imp
			imp.close()
		else:
			bkg = imp
			imp.close()
	ic =  ImageCalculator()
	img2 = ic.run("Subtract create 32-bit stack",img,bkg)
	#copy the metadata
	props = img.getProperties()
	for prop in props:
		img2.setProperty(prop,props.getProperty(prop))
	img.close()
	bkg.close()
	return img2

def close_imgs():
	imgs = WindowManager.getImageTitles()
	for img in imgs:
		im = WindowManager.getImage(img)
		im.close()
		
close_imgs()
run_script()