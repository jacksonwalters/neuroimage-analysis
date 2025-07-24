# neuroimage-analysis
This script provides basic visualizations of fMRI brain scans in MATLAB.

**current dataset**: https://openneuro.org/datasets/ds000114/versions/1.0.2

**paper**: https://pmc.ncbi.nlm.nih.gov/articles/PMC3641991/pdf/2047-217X-2-6.pdf

**downloading the data**: Use the shell script `ds000114-1.0.2.sh` which includes `curl` commands. Change the permissions to make it executable:

`
chmod +x ds000114-1.0.2.sh
`

Then run 

`./ds000114-1.0.2.sh`

to download the dataset which may take a few minutes. Any directory can be used, but be sure to set the path to the data files.

Currently the `ds000114_sub_01_analysis.m` script:
  - loads both functional (func) and anatomical data (anat)
  - produces three animations as .gif files [temporal functional, spatial functional, spatial anatomical]
  - computes basic statistics
  - outputs a time series for a given voxel

**paths**: There are two paths depending on whether you'd like to use some sample data, or point to the full dataset.

- local test data path in repository: `'/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis/data'`
- data downloaded from shell script: `'/Users/jacksonwalters/Documents/GitHub/neuroimage-analysis/ds000114-1.0.2'`

**datasets:**
- https://community.ukbiobank.ac.uk/hc/en-gb/articles/24618819821981-Imaging-Data
- https://www.humanconnectome.org/study/hcp-young-adult
- https://openneuro.org

**future brain imaging methods**:
- DTI [diffuse tensor imaging, https://www.diffusion-imaging.com/]
- MRA [magnetic resonance angiography]

**future topics**:
- multi-modal studies [combining different data types; genetic, questionaire data, GWAS etc.]
- neurodegenerative bases for disorders such as bipolar, schizophrenia [e.g. myelin sheath decay]
