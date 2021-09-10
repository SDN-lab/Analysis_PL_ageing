function data = loadPresentation(file_path)
    [~, out1] = importPresentationLog(file_path);         % call the importPresentationLog function that reads logfile Presentation data into matlab
    
    %% calculate RTs
    
    rt_stim_pair  = {'stim_'};                                                   % the string to look for in out1.code that indicates an instruction cue has been presented
    
    
    for i=1:length(out1.code)                                                    % start a loop that goes through the length of out1.ode and looks for 'cue_'
        data.rt_stim_pair(i) = strncmpi(rt_stim_pair,out1.code{i}, 4);           % find strings in the column out1.code that start with cue_ (so the first four letters) it gives it a 1 if true and 0 if false
    end
    
    
    for i=1:length(out1.code)                                                    % Now pull out the text from out1.code only when a cue was being
        if data.rt_stim_pair(i)     == 1                                         % presented (this will be a 1 in your data.was_instruct variable) and NaN when it was any other stimulus (as this will be a 0 in data.was_instruct.
            data.resp_time_report(i) = out1.ttime(i+1);                          % take the RT as the next number along in the ttime column
            
        elseif data.rt_stim_pair(i) == 0
            data.resp_time_report(i) = -99;
        end
    end
    % this function removes the 'nan' leaving only the items from out1.code that began with 'cue_'
    
    data.resp_time_report(:, any(data.resp_time_report==-99,1)) = [];
    
    data.rt= (data.resp_time_report'/10);
    
    
    %% From the "out1.code" variable extract the "inst_" stimuli and create a new variable that outputs whther it was a self other or no one block and the onset time of the instruction cue, 9 cues
    
    instruc_cue  = {'inst_'};                                                    % the string to look for in out1.code that indicates an instruction cue has been presented
    
    
    for i=1:length(out1.code)                                                    % start a loop that goes through the length of out1.ode and looks for 'inst_'
        data.was_instruc(i) = strncmpi(instruc_cue,out1.code{i}, 4);             % find strings in the column out1.code that start with inst_ (so the first four letters) it gives it a 1 if true and 0 if false
    end
    
    
    for i=1:length(out1.code)                                                    % Now pull out the text from out1.code only when a inst cue was being
        if data.was_instruc(i)     == 1                                          % presented (this will be a 1 in your data.was_instruct variable) and NaN when it was any other stimulus (as this will be a 0 in data.was_instruct. Also pull out the
            data.inst_time_report(i) = out1.time(i);
            data.inst_report{i}  = out1.code{i};                                 % if a inst cue was presented look in the out1.time column to get the onset time that the cue was presented (or a 0 if it was any other stimulus)
            
        elseif data.was_instruc(i) == 0
            data.inst_report{i} = NaN;                                           % after this loop the cells in data.inst_report will be 'nan' if they werent beginning with 'cue_'
            data.inst_time_report(i)= 0;
        end
    end
    
    
    fh = @(x) all(isnan(x(:)));                                                  % this function removes the 'nan' leaving only the items from out1.code that began with 'inst_'
    data.inst_report(cellfun(fh, data.inst_report)) = [];                        % cellfun: Apply a function to each cell of a cell array.
    
    data.inst_num = cellfun(@(z) z(6), data.inst_report, 'UniformOutput', false);% This extracts the sixth (z(6)) character, which I have coded as number 1-4 to specify which cue wwas being presented
    data.inst_times = nonzeros(data.inst_time_report'/10000);                    % This gets rid of the zeros from the variable containing zeros for any other stimulus and a number whe a cue was presented, so will just leave whetehr each cue was 1-4
    
    for i = 1:length(data.inst_num)
        data.inst(i) = str2num(data.inst_num{i});                                % This converts the string to a number
    end
    
    data.inst = data.inst';                                                      % This makes it a column not a row
    
    
    %% From the "out1.code" variable extract the "cue" stimuli and create a new variable that outputs whether it is a self, other or no one trial, a separate variable that is the onset time of the cue and later I can create which stimuli pair it was
    
    stim_pair  = {'stim_'};                                                      % the string to look for in out1.code that indicates an instruction cue has been presented
    
    
    for i=1:length(out1.code)                                                    % start a loop that goes through the length of out1.ode and looks for 'cue_'
        data.was_stim_pair(i) = strncmpi(stim_pair,out1.code{i}, 4);             % find strings in the column out1.code that start with cue_ (so the first four letters) it gives it a 1 if true and 0 if false
    end
    
    
    for i=1:length(out1.code)                                                    % Now pull out the text from out1.code only when a cue was being
        if data.was_stim_pair(i)     == 1                                        % presented (this will be a 1 in your data.was_instruct variable) and NaN when it was any other stimulus (as this will be a 0 in data.was_instruct. Also pull out the
            data.stim_time_report(i) = out1.time(i);
            data.stim_report{i}  = out1.code{i};
            data.resp_time_report(i) = out1.ttime(i+1);                          % take the RT as the next number along in the ttime column
            
        elseif data.was_stim_pair(i) == 0
            data.stim_report{i} = NaN;                                           % after this loop the cells in data.cue_report will be 'nan' if they werent beginning with 'cue_'
            data.stim_time_report(i)= 0;
            data.resp_time_report(i) = -99;
        end
    end
    
    
    fh = @(x) all(isnan(x(:)));                                                  % this function removes the 'nan' leaving only the items from out1.code that began with 'cue_'
    data.stim_report(cellfun(fh, data.stim_report)) = [];
    
    data.stim_num = cellfun(@(z) z(6), data.stim_report, 'UniformOutput', false);% This extracts the fifth (z(5)) character, which I have coded as number 1-4 to specify which cue was being presented
    
    data.high_left = cellfun(@(z) z(8), data.stim_report, 'UniformOutput', false);
    
    data.high_right = cellfun(@(z) z(10), data.stim_report, 'UniformOutput', false);
    
    data.order = cellfun(@(z) z(12), data.stim_report, 'UniformOutput', false);
    
    data.stim_times = nonzeros(data.stim_time_report'/10000);                     % This gets rid of the zeros from the variable containing zeros for any other stimulus and a number whe a cue was presented, so will just leave whether each cue was 1-4
    
    for i = 1:length(data.stim_num)
        data.stim(i) = str2num(data.stim_num{i});                                 % This converts the string to a number
    end
    
    data.stim = data.stim';
    
    for i = 1:length(data.high_left)
        data.high_L(i) = str2num(data.high_left{i});                              % This converts the string to a number
    end
    
    data.high_L = data.high_L';
    
    for i = 1:length(data.high_right)
        data.high_R(i) = str2num(data.high_right{i});                             % This converts the string to a number
    end
    
    data.high_R = data.high_R'; % This makes it a column not a row
    
    for i=1:length(data.order)
        data.stim_order(i) =str2num(data.order{i});
    end
    
    data.stim_order =data.stim_order';
    
    
    %% %% From the "out1.code" variable extract the outcome stimuli and create a new variable that outputs what the outcome type was on each trial and the onset time of the outcome cue on each trial
    
    outcome_code = {'out_'};                                                      % start a loop that goes through the length of out1.ode and looks for 'out_' different ones are e.g. out_
    
    for i=1:length(out1.code)
        data.was_outco(i) = strncmpi(outcome_code,out1.code{i}, 4);               % find strings in the column out1.code that start with out_ (so the first four letters)
    end
    
    for i=1:length(out1.code)
        if data.was_outco(i)             == 1
            data.outco_time_report(i)     = out1.time(i);                         % what time was the outcome cue presented? look in out1.time whenever it is an outcome cue
            data.outco_report{i}          = out1.code{i};
            
        elseif data.was_outco(i)         == 0
            data.outco_report{i}      = NaN;
            data.outco_time_report(i) = 0;
        end
    end
    
    % after this loop the cells in data.outco_report will be 'nan' if not an outcome cue
    fh = @(x) all(isnan(x(:)));                                                   % this function removes the 'nan' leaving only the items from out1.code that began with 'out_'
    data.outco_report(cellfun(fh, data.outco_report)) = [];                       % cellfun: Apply a function to each cell of a cell array where if it is a nan remove it
    
    data.outco_num = cellfun(@(z) z(5), data.outco_report, 'UniformOutput', false);% This extracts the fifth (z(5)) character
    
    data.reward = cellfun(@(z) z(7), data.outco_report, 'UniformOutput', false);
    
    data.chosen = cellfun(@(z) z(9), data.outco_report, 'UniformOutput', false);  % in the outcome code it also specifies what stimuli the participant picked. If they didnt pick something it is a '9'
  
    data.outco_times = nonzeros(data.outco_time_report'/10000);                   % This gets rid of the zeros from the variable containing zeros for any other stimulus and a number whe a outcome was presented.
    
    %     Make a column stating if the trial is a self, other or no one trial
%     (data.cond) then a variable saying whether it was the first, second of
%     this pair of stimuli for that condition (data.pair)
    for i=1:length(data.stim)
        if data.stim(i)        ==1
            data.cond(i)        =1;
            data.pair(i)        =1;
            
            
        elseif data.stim(i)    ==2
            data.cond(i)        =1;
            data.pair(i)        =2;
            
            
        elseif data.stim(i)    ==3
            data.cond(i)       =1;
            data.pair(i)       =3;
            
            
        elseif data.stim(i)    ==4
            data.cond(i)       =2;
            data.pair(i)       =1;
            
        elseif data.stim(i)    ==5
            data.cond(i)       =2;
            data.pair(i)       =2;
            
        elseif data.stim(i)    ==6
            data.cond(i)      =2;
            data.pair(i)      =3;
            
            
        elseif data.stim(i)    ==7
            data.cond(i)       =3;
            data.pair(i)       =1;
            
        elseif data.stim(i)    ==8
            data.cond(i)       =3;
            data.pair(i)       =2;
            
        else
            data.cond(i)      =3;
            data.pair(i)      =3;
            
        end
    end
    
%     Get rid of the missed trials from the data.choices and data.
%     rewarded variables that go into the model by using the function nonzeros and create a new variable
%     called data.choices all that keeps all choices in place and makes missed
%     trials NaNs so I can paste that column into excel to make the learning graph
%     
%     for i=1:length(data.choices)
%         if data.choices(i) ==9
%             data.rewardednew(i) = 0;
%             data.choicesnew(i) =0;
%             data.condnew(i) = 0;
%             data.stimordernew(i) = 0;
%             data.choices_all(i) =NaN;
%             
%         elseif data.choices(i)==0
%             data.choicesnew(i)= 1;
%             data.rewardednew(i)= data.rewarded(i)+1;
%             data.condnew(i) = data.cond(i);
%             data.stimordernew(i) = data.stim_order(i);
%             data.choices_all(i)=data.choices(i);
%             
%         elseif data.choices(i)==1
%             data.choicesnew(i)=2;
%             data.rewardednew(i)= data.rewarded(i)+1;
%             data.condnew(i) = data.cond(i);
%             data.stimordernew(i) = data.stim_order(i);
%             data.choices_all(i)=data.choices(i);
%         end
%     end
    
end

