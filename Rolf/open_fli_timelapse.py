# @File ReferenceFile
# @File SampleFile

#import BioFormats
from loci.plugins import BF
from loci.plugins.in import ImporterOptions
#import Image Calculator for background subtraction
from ij.plugin import ImageCalculator
#some ij functionality
from ij import IJ 
from ij.process import AutoThresholder
from ij import CompositeImage
from ij import ImagePlus

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
	result = IJ.getImage()
	#Stack to Hyperstack
	result.setDimensions(3, 1, 1)
	result = CompositeImage(result)
	result.setOpenAsHyperStack(1)
	result.updateAndDraw()

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
	
run_script()