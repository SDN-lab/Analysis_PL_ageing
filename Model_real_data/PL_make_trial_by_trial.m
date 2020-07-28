% Script to create the following excel files from the .mat structure
% containing information about the trial by trial performance of each
% participant on the prosocial learning task:
% 1. trial by trial data in long format
% 2. average for each participant of percentage correct, RT etc across the 3 trials in each of 3 blocks for an agent (i.e. average for three trial1 trials for self etc)
% 3. average across participants of 2 groups.

% Jo Cutler Feb 2020

clear all

load('Combined_data_152.mat') % enter path to .mat file with structure s containing all participants' data

n = length(s.PL.ID); % number of participants
t = length(s.PL.beh{1,1}.agent); % number of trials

titles = {'ID', 'agent', 'choice', 'outcome', 'RT', 'block', 'group', 'trialno'}; % columns want in the trial by trial dataset
avtitles = {'ID', 'group', 'agent', 'choice1', 'choice0', 'miss', 'out1', 'out0', 'RT', 'choiceP', 'trialno'}; % columns want in dataset of averages per participant
ttitles = {'group', 'agent', 'choice1', 'choice0', 'miss', 'out1', 'out0', 'RT', 'choiceP', 'trialno'}; % columns want in the total averages dataset

c = length(titles); % number of columns
avc = length(avtitles);
tc = length(ttitles);

tbtdata = nan([(n*t),c],'double'); % create matrices of nan the desired size to fill in
avdata = nan([(n*t/3),avc],'double');
tdata = nan([t/3,tc],'double');

% create tbtdata - one row per trial, per participant

for k = 1:n % loop over each participant
    
    b = ((k - 1) * t) + 1; % first row in tbtdata for that participant
    e = b + t - 1; % last row in tbtdata for that participant
    
    code = s.PL.ID{1, k}.ID{1, 1}; % participant ID code
    code(isletter(code)) = []; % remove any letters from code
    code = str2num(erase(code,'.')); % remove any '.' from code
    
    tbtdata(b:e,1) = code; % 1st column = participant ID
    tbtdata(b:e,2) = s.PL.beh{1,k}.agent; % 2nd column = agent
    tbtdata(b:e,3) = s.PL.beh{1,k}.choice; % 3rd column = choice (1 = high reward, 0 = low reward, 9 = missed)
    tbtdata(b:e,4) = s.PL.beh{1,k}.outcome; % 4th column = outcome (1 = rewarded, 0 = not rewarded)
    tbtdata(b:e,5) = s.PL.beh{1,k}.RT; % 5th column = reaction time
    tbtdata(b:e,6) = s.PL.beh{1,k}.block; % 6th column = block number
    if code < 200 % s.PL.beh.group was zero - adjust this to be 1 (young) or 2 (old) based on ID code
    tbtdata(b:e,7) = 1; % 7th column = group
    elseif code >= 200
    tbtdata(b:e,7) = 2;    
    end
    tbtdata(b:e,8) = [1:16, 1:16, 1:16, 1:16, 1:16, 1:16, 1:16, 1:16, 1:16]'; % 8th column = trial number
    
end

tbtdata(find(tbtdata(:,3) == 9),3:5) = NaN; % replace missed trials (9) with NaN in choice column

% create avdata - one row per trial number (averaged over 3 times), per participant

row = 1;
for k = 1:n % loop over each participant
    
    b = ((k - 1) * t) + 1; % first row in tbtdata for that participant
    e = b + t - 1; % last row in tbtdata for that participant
    
    pdata = tbtdata(b:e,:); % extract participant's data into separate variable
    
    avb = ((k - 1) * (t/3)) + 1; % first row in avdata for that participant
    ave = avb + (t/3) - 1; % last row in avdata for that participant
    
    avdata(avb:ave,1) = pdata(1,1); % 1st column = participant ID
    avdata(avb:ave,2) = pdata(1,7);; % 2nd column = group
    
    for a = 1:3 % loop over each agent
        for tn = 1:16 % loop over each trial in block
            ind = find(pdata(:,2) == a & pdata(:,8) == tn); % index of that agent & trial number
            avdata(row,3) = a; % 3rd column = agent
            avdata(row,4) = sum(pdata(ind,3) == 1); % 4th column = how many correct (high reward) choices
            avdata(row,5) = sum(pdata(ind,3) == 0); % 5th column = how many incorrect choices
            avdata(row,6) = sum(isnan(pdata(ind,3))); % 6th column = how many choices missed
            avdata(row,7) = sum(pdata(ind,4) == 1); % 7th column = how many trials rewarded
            avdata(row,8) = sum(pdata(ind,4) == 0); % 8th column = how many trials not rewarded
            avdata(row,9) = nanmean(pdata(ind,5)); % 9th column = average reaction time
            avdata(row,10) = ((avdata(row,4)) / (avdata(row,4) + avdata(row,5))) * 100; 
            % 10th column = percentage of choices made (ignoring missed) that were the high reward option
            avdata(row,11) = tn; % 11th column = trial number
            row = row + 1;
        end
    end
    
end

% create t data - one row per trial averaged over 3 times and all participants in each group separately

row = 1;
for g = 1:2 % loop over each group
for a = 1:3 % loop over each agent
    for tn = 1:16 % loop over each trial
        ind = find(avdata(:,3) == a & avdata(:,11) == tn & avdata(:,2) == g); % find the rows that match criteria
        tdata(row,1) = g; % 1st column = group
        tdata(row,2) = a; % 2nd column = agent
        tdata(row,3) = nanmean(avdata(ind,4)); % 3rd column = average number of correct (high reward) choices
        tdata(row,4) = nanmean(avdata(ind,5)); % 4th column = average number of incorrect choices
        tdata(row,5) = nanmean(avdata(ind,6)); % 5th column = average number of missed choices
        tdata(row,6) = nanmean(avdata(ind,7)); % 6th column = average number of rewarded trials
        tdata(row,7) = nanmean(avdata(ind,8)); % 7th column = average number of not rewarded trials
        tdata(row,8) = nanmean(avdata(ind,9)); % 8th column = average reaction time
        tdata(row,9) = nanmean(avdata(ind,10)); % average percentage correct (ignoring missed)
        tdata(row,10) = tn; % 10th column = trial number
        row = row + 1;
    end
end
end

% convert matrices to tables with titles
tbt = cell2table(num2cell(tbtdata), 'VariableNames', titles);
av = cell2table(num2cell(avdata), 'VariableNames', avtitles);
t = cell2table(num2cell(tdata), 'VariableNames', ttitles);

% save tables as excel files
writetable(tbt,['../Prosocial_learning_R_code/Task_data_trial_by_trial.xlsx'])
writetable(av,['../Prosocial_learning_R_code/Task_data_participant_averages.xlsx'])
writetable(t,['../Prosocial_learning_R_code/Task_data_overall_averages.xlsx'])
