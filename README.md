# DECIPHER
**Version 1.21** *Updated April 2024*\
*Developed by Mark Cherepashensky from the [Ji-Xin Cheng Group of Boston University](https://sites.bu.edu/cheng-group/)*
![Central Interface for DECIPHER](https://i.imgur.com/XuZUKJa.png)
DECIPHER (Denosing Elements, Clearing Interference, and Processing Hyperspectral Endmembers for Research) is a MATLAB-based analysis program designed to process hyperspectral image stacks. Using an intuitive UI with a robust and expanding feature set, the pipeline from raw to processed images is now easier to use and faster simultaneously. This can be run with any type of hyperspectral data, though it was primarily developed with SRS acquired image stacks.

*Demo data is available on [Google Drive](https://drive.google.com/drive/folders/1MvYJIIbNUKU04xALBnq612Ed2gQi-KZt?usp=sharing).*

## Key Features
![Workflow Overview](https://i.imgur.com/B5brRvC.png)
 - Support for raw image stacks in both .txt and .tiff format, imported as whole folder data sets for bulk processing
 - Hooks to process data with BM4D, both standard profiles and custom ones
 - Background removal with binary mask subtraction, Gaussian blurring, and median filtering
 - Pure chemical reference management with spectral fitting, color selection, and multi-ROI selection
 - Spectral chemical reference management with polynomial shifting for wavelengths
 - Generate chemical composition unmixing maps using non-negative lasso, optimized for multiple lambda values and quick runtime using parallel processing
 - Full contrast/brightness adjustment with key-frames selection, multi-color composite image generation, and additional z-projection generation with simultaneous adjustments for all data
 - Previewing on all operations and intuitive adjustments for any parameter
 - Dynamic UI to fit multiple screen resolutions and adapt to different operating systems (Windows, MacOS, and Linux)

## Updates
### Version 1.21
- Support for existing reference spectra in *.txt or *.mat files
- Improvements to importing data and data management for primary and reference data
- Bug fixes for background removal range display and spectra exports for visualization

*For a full list of improvements, see the changelog included in the repository*

### Future Features
 While potentially not pending for the next update, these are eventual features that will soon be implemented and available for public use
 - Menu bar allowing users to customize and remove features
 - Stitching loaded hyperspectral stacks into composite image stacks
 - Automatic lambda calculation for lasso
 - Quantification UI to analyze processed, unmixed images
 - Scale bar addition and multiple image export types
 
*To report a bug or suggest a feature, feel free to contact the author at themarkc@bu.edu.*

 *[Non-Negative Lasso](https://github.com/buchenglab/nonneg_LASSO_spectral_unmixing) was developed by [Haonan Lin](https://sites.google.com/view/hnlin) at the Ji-Xin Cheng Group and served as the basis for the version packaged with this software. [BM4D](https://webpages.tuni.fi/foi/GCF-BM3D/) was developed by Tampere University and is connectable to this software. Special thanks also goes to Chinmayee Prabhu Dessai, Vikrant Sharma, and Meng Zhang for testing and feedback.*

***The associated code is distributed without any warranty, and without implied warranty of merchantability or fitness for a particular purpose. Distribution of this work for commercial purposes is prohibited. This work can be redistributed and/or modified for non-commercial purposes. Publications that use this code or modified instances should credit the author(s) appropriately.***
