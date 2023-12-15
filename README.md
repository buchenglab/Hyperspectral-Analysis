# Hyperspectral-Analysis
**Version 0.9** *December 2023*
*Developed by Mark Cherepashensky at the Ji-Xin Cheng Group of Boston University.*
![Central Interface for Hyperspectral Analysis](https://i.imgur.com/XTPyQdh.png)
Hyperspectral Analysis is a MATLAB-based analysis program designed to process hyperspectral image stacks. Using an intuitive UI with a robust and expanding feature set, the pipeline from raw to processed images is now easier to use and faster simultaneously. This open and easily modifiable script can be run with any type of hyperspectral data, though it was primarily developed with SRS and MIP acquired image stacks.

## Key Features
 - Support for raw image stacks in both .txt and .tiff format, imported as whole folder data sets for bulk processing
 - Background removal with binary mask subtraction and/or Gaussian blurring
 - Pure chemical reference management with spectral fitting, color selection, and multi-ROI selection
 - Generate chemical composition unmixing maps using non-negative lasso, optimized for multiple lambda values and quick runtime using parallel processing
 - Previewing on all operations and intuitive adjustments for any parameter
 - Dynamic UI to fit multiple screen resolutions and adapt to different operating systems (Windows, MacOS, and Linux)

## Version 1.0 Upcoming Features
 - Advanced export control to save raw image stacks, processed image stacks, individual unmixed images, composite images, and more
 - Ability to adjust contrast and brightness for export .tiff and .gif files
 - Cleaner composite image generation
 - Requested adjustments to the binary mask UI to improve ease of use and flexibility
 - Exported processing overview .txt with all steps taken and parameters associated
 - Additional tooltips to cover features
 - Quality of life features and improvements to stability & performance

### Future Features
 While not pending for the next update, these are eventual features that will soon be implemented and available for public use
 - BM4D image denoising and an associated UI
 - More export options:
	 - Other z-projections (min/max intensity, sum of slices, median, etc.)
	 - Key frames selection UI and export
	 - Scale bars on images
 - Menu bar allowing users to customize and remove features
 - Stitching loaded hyperspectral stacks into composite images
 - Automatic lambda calculation for lasso
 - Connections to other denoising packages (including Python-based ones)
 - User manual on GitHub with full visual explanations of all features
 
*To report a bug or suggest a feature, feel free to contact the author at themarkc@bu.edu.*


 *[Non-Negative Lasso](https://github.com/buchenglab/nonneg_LASSO_spectral_unmixing) was developed by [Haonan Lin](https://sites.google.com/view/hnlin) at the Ji-Xin Cheng Group and served as the basis for the version packaged with this software. Special thanks also goes to Chinmayee Prabhu Dessai and Meng Zhang for testing and feedback.*

***The associated code is distributed without any warranty, and without implied warranty of merchantability or fitness for a particular purpose. Distribution of this work for commercial purposes is prohibited. This work can be redistributed and/or modified for non-commercial purposes. Publications that use this code or modified instances should credit the author(s) appropriately.***
