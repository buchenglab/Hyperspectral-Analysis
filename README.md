# Hyperspectral-Analysis
**Version 0.98** *Updated April 2024*\
*Developed by Mark Cherepashensky from the [Ji-Xin Cheng Group of Boston University](https://sites.bu.edu/cheng-group/)*
![Central Interface for Hyperspectral Analysis](https://i.imgur.com/rOLRrjE.png)
Hyperspectral Analysis is a MATLAB-based analysis program designed to process hyperspectral image stacks. Using an intuitive UI with a robust and expanding feature set, the pipeline from raw to processed images is now easier to use and faster simultaneously. This can be run with any type of hyperspectral data, though it was primarily developed with SRS and MIP acquired image stacks.

## Key Features
 - Support for raw image stacks in both .txt and .tiff format, imported as whole folder data sets for bulk processing
 - Background removal with binary mask subtraction and/or Gaussian blurring
 - Pure chemical reference management with spectral fitting, color selection, and multi-ROI selection
 - Generate chemical composition unmixing maps using non-negative lasso, optimized for multiple lambda values and quick runtime using parallel processing
 - Full contrast/brightness adjustment with key-frames selection, multi-color composite image generation, and additional z-projection generation with simultaneous adjustments for all data
 - Previewing on all operations and intuitive adjustments for any parameter
 - Dynamic UI to fit multiple screen resolutions and adapt to different operating systems (Windows, MacOS, and Linux)

## Updates
### Changes from Version 0.95
- Toolbox build for easier install and maintenance
- Parameter list and additional export options
- Added support for 3K displays with adjusted implementation of ResolutionScaler
- Unmixing checkbox for LASSO to prevent unnecessary previews
- Update to Path for better reliability and saving procedures
- Error catching and crash failure in chemical reference imports
- New prompts and checks for directorys, workspace variables, and overwrites
*For a full list of improvements, see the changelog included in the repository*

### Features for Version 1.0
 - A new interface for BM#D is in development and will be available soon
 - Windowed Z-Projections

### Future Features
 While potentially not pending for the next update, these are eventual features that will soon be implemented and available for public use
 - Menu bar allowing users to customize and remove features
 - Stitching loaded hyperspectral stacks into composite image stacks
 - Automatic lambda calculation for lasso
 - Quantification UI to analyze processed, unmixed images
 - Scale bar addition and multiple image export types
 - Accelerating LASSO execution with gpuArrays and/or fmincon
 - Connections to other denoising packages (including Python-based ones)
 
*To report a bug or suggest a feature, feel free to contact the author at themarkc@bu.edu.*

 *[Non-Negative Lasso](https://github.com/buchenglab/nonneg_LASSO_spectral_unmixing) was developed by [Haonan Lin](https://sites.google.com/view/hnlin) at the Ji-Xin Cheng Group and served as the basis for the version packaged with this software. Special thanks also goes to Chinmayee Prabhu Dessai and Meng Zhang for testing and feedback.*

***The associated code is distributed without any warranty, and without implied warranty of merchantability or fitness for a particular purpose. Distribution of this work for commercial purposes is prohibited. This work can be redistributed and/or modified for non-commercial purposes. Publications that use this code or modified instances should credit the author(s) appropriately.***
