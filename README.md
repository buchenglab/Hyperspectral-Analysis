# Hyperspectral-Analysis
**Version 0.95** *Updated February 2024*\
*Developed by Mark Cherepashensky from the [Ji-Xin Cheng Group of Boston University](https://sites.bu.edu/cheng-group/)*
![Central Interface for Hyperspectral Analysis](https://i.imgur.com/XTPyQdh.png)
Hyperspectral Analysis is a MATLAB-based analysis program designed to process hyperspectral image stacks. Using an intuitive UI with a robust and expanding feature set, the pipeline from raw to processed images is now easier to use and faster simultaneously. This open and easily modifiable script can be run with any type of hyperspectral data, though it was primarily developed with SRS and MIP acquired image stacks.

## Key Features
 - Support for raw image stacks in both .txt and .tiff format, imported as whole folder data sets for bulk processing
 - Background removal with binary mask subtraction and/or Gaussian blurring
 - Pure chemical reference management with spectral fitting, color selection, and multi-ROI selection
 - Generate chemical composition unmixing maps using non-negative lasso, optimized for multiple lambda values and quick runtime using parallel processing
 - Full contrast/brightness adjustment with key-frames selection, multi-color composite image generation, and additional z-projection generation with simultaneous adjustments for all data
 - Previewing on all operations and intuitive adjustments for any parameter
 - Dynamic UI to fit multiple screen resolutions and adapt to different operating systems (Windows, MacOS, and Linux)

## Updates
### Changes from Version 0.9
- A Contrast/Brightness adjustment UI that can handle multiple z-projections, adjustments to components of composite images, key frame selections per component, and previewing across different datasets
- A fuller export UI where users can select from a variety of parameters
- Several bug fixes with how LASSO progress and results were displayed
- Robust handling of user errors to minimize crashes and unintended failures
- Improved speed and efficiency, capable of handling more data sets
- Export images as .tif files and stacks a .gif files
*For a full list of improvements, see the changelog included in the repository*
### Features for Version 1.0
 - A new interface for BM#D is in development to support importing as a package rather than including
 - Tooltips for all features to explain the processes in greater detail and understand what each parameter means
 - Quality of life features like quick LASSO parameter input, reference color exceptions, and a parameter list for export
 - Save states to return to interrupted workflows

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
