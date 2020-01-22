# read_dicom_file

## Dicom file format
Digital Imaging and COmmunication in Medicine is "the common language of medical equipment". Header and Image data are stored in the same file.
### Header
Header stores hundreds of pieces of information including patient, machine, and data acquisition.

### Image
Image is a gray scale image slice data.

## Image processing 

### Extract data
By extractiong the raw image captured from image in the dicom file, we can confine to the area we are interested in.

### Thresholding
Thresholding is a method of image segmentation, converting gray scale images into binary images.

By replacing each pixel in the image with black(0) or white(1) pixel using specific grayscale value.

### Create ETA
ETA is a variable in Direct Foring Immersed Boundary method to define fluid or solid domain.

ETA = 0 : fluid domain

ETA = 1 : solid domain

### Assembling
By assembling a series of slice images, 3D model can be created and be applied to CFD simulations.
