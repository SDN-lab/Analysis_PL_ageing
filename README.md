This folder contains the scripts and functions to run:

i) learning models (with expectation maximisation; em) on participant data [subfolder Model_real_data]
ii) analysis on the model parameters and trial by trial behavioural data [subfolder Prosocial_learning_R_code]
iii) model identifiability and parameter recovery [subfolder Model_simulated_data]

# For analysis of the real participant data (i & ii):

## Step 1 - run Run_em_model.m to run and compare models using expectation maximisation fit

### Output from script
   - workspaces/EM_fit_results_[date] has all variables from script
           - 's.PL.em' contains model results including the model parameters for each participant
   - datafiles in specified output directory:
       - PL_model_fit_statistics.xlsx - model comparison fit statistics
       - EM_fit_parameters.xlsx - estimated parameters for each participant
       - Compare_fit_between_groups.xlsx - median R^2 for each participant with group index

## Step 3 - match parameters from PL_model_fit_statistics with other behavioural data in a wide data format for analysis (see PL_152_combined_data_share.xlsx)

## Step 4 - run PL_make_trial_by_trial.m to generate data files of behavioural data

### Output from script
   - datafiles in specified output directory:
       - Task_data_trial_by_trial.xlsx - trial by trial data in long format
       - Task_data_participant_averages.xlsx - average for each participant of percentage correct, RT etc across the 3 trials in each of 3 blocks for an agent
       - Task_data_overall_averages.xlsx - average across participants of 2 groups

## Step 5 - run analysis using R project, Prosocial_learning_analysis.Rmd script, and files from above output (note sections of this script also plot results from simulation experiments (model identifiability and parameter recovery - see below)

# For simulation experiments (iii):

## Step 1 - run the Simulate_PR_MI.m script to run model identifiability and / or parameter recovery (currently only EM fit implemented)

## Step 2 - plot results using R project, Prosocial_learning_analysis.Rmd script

# Prosocial learning models based Lockwood et PL. (2016), PNAS
test different variations of learning rate and beta parameters

### Models compared:
#### M1 = 'RWPL' beta, alpha
simple RL model with one beta and one learning rate

#### M2 = 'RWPL_SO_LR' 
beta, self LR, other LR, no one LR: RL model with a self other & no one separate learning rates and one beta parameter

#### M3 = 'RWPL_SO_comb' 
RL model with a combined self and other (other & no one) learning rate and one beta parameter - beta, self LR, other LR

#### M4 = 'RWPL_SON_LR_SON_beta'
original model from PNAS with 3 learning rates and 3 betas - beta self, beta other, beta no one, self LR, other LR, no one LR