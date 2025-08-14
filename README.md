# neuroimage-analysis
These scripts provide visualizations of brain scan data in MATLAB.

We analyze both fMRI [functional magnetic resonance imaging] data and utilize DTI [diffusion tensor imaging] methods.

**current dataset**: https://openneuro.org/datasets/ds000114/versions/1.0.2

**paper**: https://pmc.ncbi.nlm.nih.gov/articles/PMC3641991/pdf/2047-217X-2-6.pdf

**downloading the data**: Use the shell script `ds000114-1.0.2.sh` which includes `curl` commands. Change the permissions to make it executable:

`chmod +x ds000114-1.0.2.sh`

Then run 

`./ds000114-1.0.2.sh`

to download the dataset which may take a few minutes.

**fMRI animations**: 
  - script = `ds000114_basic_animations_statistics.m`
  - loads both functional (func) and anatomical data (anat)
  - produces three animations as .gif files [temporal functional, spatial functional, spatial anatomical]
  - computes basic statistics
  - outputs a time series for a given voxel

**DTI visualizations**:
- guide: https://www.diffusion-imaging.com/
- script = `ds000114_dti_examples.m`
- computes four DTI values [AD, RD, MD, FA] for fixed voxel in `ds000114-1.0.2`
- computes [AD, RD, MD, FA] for across slices
- displays and saves resulting 2d images

**activation examples**
- script = `ds000114_activation_examples.m`
- set paths for the dataset and GitHub project folder
- define canonical HRF (double gamma) for modeling brain response
- loop over subjects to load fMRI data and event timing
- build design matrix by convolving condition onsets with HRF
- fit voxelwise GLM to estimate beta maps for each condition
- save PNGs showing all conditions for each subject and the group average

**paths**: Ensure your path is set appropriately (change the username). Place the data downloaded from the shell script in the GitHub repository root directory.

- data downloaded from shell script: `'/Users/<your-username-here>/Documents/GitHub/neuroimage-analysis/ds000114-1.0.2'`

**datasets:**
- https://community.ukbiobank.ac.uk/hc/en-gb/articles/24618819821981-Imaging-Data
- https://www.humanconnectome.org/study/hcp-young-adult
- https://openneuro.org

**future brain imaging methods**:
- MRA [magnetic resonance angiography]

**future topics**:
- multi-modal studies [combining different data types; genetic, questionaire data, GWAS etc.]
- neurodegenerative bases for disorders such as bipolar, schizophrenia [e.g. myelination]

**articles**:
- https://www.diffusion-imaging.com/2015/10/what-is-diffusion-tensor.html
- https://www.diffusion-imaging.com/2013/01/relation-between-neural-microstructure.html
- https://www.frontiersin.org/journals/neuroscience/articles/10.3389/fnins.2013.00031/full
