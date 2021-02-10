### This folder contains the scripts and functions to run:

- #### i) learning models (with expectation maximisation; em) on participant data [subfolder Model_real_data]
- #### ii) analysis on the model parameters and trial by trial behavioural data [subfolder Prosocial_learning_R_code]
- #### iii) model identifiability and parameter recovery [subfolder Model_simulated_data]

[Click here to view plots and main results](https://github.com/SDN-lab/Analysis_PL_ageing/blob/master/Prosocial_learning_R_code/Prosocial_learning_analysis.md)

### For analysis of the real participant data (i & ii):

#### Step 1 - Run_em_model.m 
Script to run and compare models using expectation maximisation fit

##### Output from script
   - workspaces/EM_fit_results_[date] has all variables from script
           - 's.PL.em' contains model results including the model parameters for each participant
   - datafiles in specified output directory:
       - PL_model_fit_statistics.xlsx - model comparison fit statistics
       - EM_fit_parameters.xlsx - estimated parameters for each participant
       - Compare_fit_between_groups.xlsx - median R^2 for each participant with group index

#### Step 2 - create datafile
Match parameters from PL_model_fit_statistics with other behavioural data in a wide data format for analysis (see PL_152_combined_data_share.xlsx)

#### Step 3 - PL_make_trial_by_trial.m 
Run script to generate data files of behavioural data

##### Output from script
   - datafiles in specified output directory:
       - Task_data_trial_by_trial.xlsx - trial by trial data in long format
       - Task_data_participant_averages.xlsx - average for each participant of percentage correct, RT etc across the 3 trials in each of 3 blocks for an agent
       - Task_data_overall_averages.xlsx - average across participants of 2 groups

#### Step 4 - Prosocial_learning_analysis_show_code.Rmd
Run analysis using R project, script, and files from above output (note sections of this script also plot results from simulation experiments (model identifiability and parameter recovery - see below). Version Prosocial_learning_analysis.Rmd just runs elements for figures and tables without displaying code.

### For simulation experiments (iii):

#### Step 1 - Simulate_PR_MI.m 
Script to run model identifiability and / or parameter recovery

#### Step 2 - Prosocial_learning_analysis.Rmd 
Plot results using R script

### Prosocial learning models 
Based on [Lockwood et PL. (2016), *PNAS*](https://doi.org/10.1073/pnas.1603198113) - test different variations of learning rate and beta parameters

#### Models compared:
##### M1 = **'RWPL'**
simple RL model with one beta and one learning rate

##### M2 = **'RWPL_SO_LR'**  
beta, self LR, other LR, no one LR: RL model with a self other & no one separate learning rates and one beta parameter

##### M3 = **'RWPL_SO_comb'** 
RL model with a combined self and other (other & no one) learning rate and one beta parameter - beta, self LR, other LR

##### M4 = **'RWPL_SON_LR_SON_beta'**
original model from PNAS with 3 learning rates and 3 betas - beta self, beta other, beta no one, self LR, other LR, no one LR

### Developed using:

MATLAB 2019b

macOS 10.15 Catalina / 11.1 Big Sur
