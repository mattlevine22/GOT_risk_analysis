num_its = 1000000;
di_range = [1 6];
num_attack = 34;
num_defense = 5;
goo = zeros(1,num_its);
parfor c=1:num_its
%     num_defense = def_vec(k);
%     num_attack = attack_vec(j);
    goo(c) = FinalDiff(num_attack,num_defense,di_range);
end

figure;
subplot(1,2,1)
ksdensity(goo)
subplot(1,2,2)
ecdf(goo);

%% FUNCTIONS
function foo_diff = FinalDiff(num_attack,num_defense,di_range)
while (num_attack > 0) && (num_defense > 0)
    [num_attack,num_defense] = fooBattleCapital(num_attack,num_defense,di_range);
    %     fprintf('Number of attackers left: %d \n',num_attack);
    %     fprintf('Number of defenders left: %d \n',num_defense);
end
foo_diff = num_attack - num_defense;
end

function [num_attack,num_defense] = fooBattleCapital(num_attack,num_defense,di_range)
if num_attack==0 || num_defense==0
    return
end
attack_losses = 0;
defense_losses = 0;

n_attack_dice = min(num_attack,3);
n_defense_dice = min(num_defense,2);

attack_rolls = sort(randi(di_range,1,n_attack_dice),'descend');
defense_rolls = sort(randi(di_range,1,n_defense_dice),'descend');

% fprintf('Attack rolled: %s \n',strjoin(string(attack_rolls)));
% fprintf('Defense rolled: %s \n',strjoin(string(defense_rolls)));

di_attack = 1;
di_defense = 1;
while (di_attack <= n_attack_dice) && (di_defense <= n_defense_dice)
    best_attack = attack_rolls(di_attack);
    best_defense = defense_rolls(di_defense);
    if (best_defense + 1) >= best_attack
        attack_losses = attack_losses + 1;
    else
        defense_losses = defense_losses + 1;
    end
    di_attack = di_attack + 1;
    di_defense = di_defense + 1;
end

% fprintf('Attack loses: %s \n',strjoin(string(attack_losses)));
% fprintf('Defense loses: %s \n',strjoin(string(defense_losses)));

num_attack = num_attack - attack_losses;
num_defense = num_defense - defense_losses;

end
