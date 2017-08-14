% my_dir = '/Users/matthewlevine/code_projects/GOT_risk_analysis/';
my_dir = '.';
addpath(genpath(my_dir));

di_range = [1 6];
def_vec = 1:40;
attack_vec = 1:40;
num_its = 10000;

Y = zeros(length(def_vec),length(attack_vec));
lost_attackers = zeros(length(def_vec),length(attack_vec));

boo = 1:length(def_vec);

all_sims = zeros(length(def_vec),length(attack_vec),num_its);

parpool(12);
parfor k=boo
    k_foo = [];
    left_foo = [];
    rel_left_attacking = [];
    rel_left_defending = [];
    all_attacks = zeros(length(attack_vec),num_its);
    for j=1:length(attack_vec)
        goo = [];
        for c=1:num_its
            num_defense = def_vec(k);
            num_attack = attack_vec(j);
            goo(c) = FinalDiff(num_attack,num_defense,di_range);
        end
        all_attacks(j,:) = goo;
        k_foo(j) = sum(goo>0)/num_its;
        left_foo(j) = mean(goo);
        rel_left_attacking(j) = mean(goo)/num_attack;
        rel_left_defending(j) = mean(goo)/num_defense;
    end
    Y(:,k) = k_foo;
    lost_attackers(:,k) = left_foo;
    all_sims(k,:,:) = all_attacks;
end

save('all_sim1.mat')

%%
mean_res = mean(all_sims,3);
% rows 1-40 are 1-40 defenders
% cols 1-40 are 1-40 attackers
[X,Y] = meshgrid(def_vec,attack_vec);
fig0 = figure;
surf(X,Y,mean_res)
foo_tmp = max(max(def_vec),max(attack_vec));
caxis([-foo_tmp foo_tmp]);
colorbar;
view(2)
xlabel('Number of Attackers')
ylabel('Number of Defenders')
title(sprintf('Expected number of remaining attackers in the average capital battle.\nRemember, this does not tell you about the variance in outcomes.'))
savefig(fig0,sprintf('%s/Mean_Leftover_Attackers_GRID.fig',my_dir))
print(fig0,sprintf('%s/Mean_Leftover_Attackers_GRID.png',my_dir),'-dpng','-r300')

%%
Z = [];
rel_left_attacking = [];
rel_left_defending = [];
for k=1:length(def_vec)
    for j=1:length(attack_vec)
        num_defense = def_vec(k);
        num_attack = attack_vec(j);
        Z(j,k) = num_attack/num_defense;
        rel_left_attacking(j,k) = lost_attackers(j,k)/num_attack;
        rel_left_defending(j,k) = lost_attackers(j,k)/num_defense;
    end
end

attack_ratio = Z(:);
attack_success_rate = Y(:);

%%
fig1=figure;
plot(attack_ratio,attack_success_rate,'o')
xlabel('Number of Attackers : Number of Defenders')
ylabel('Probability of Attack Succeeding')
title('Likelihood of winning an attack on a capital')
xlim([0 5])
set(gca,'LineWidth',1.25)
set(gca,'FontSize',14)
savefig(fig1,sprintf('%s/Probability_of_Successful_Capital_Attack1.fig',my_dir))
print(fig1,sprintf('%s/Probability_of_Successful_Capital_Attack1.png',my_dir),'-dpng','-r300')

%%
fig2 = figure;
plot(attack_ratio(rel_left_attacking>0),rel_left_attacking(rel_left_attacking>0),'o');hold on;
ylabel('Fraction of Attackers Left')

plot(attack_ratio(rel_left_defending<0),abs(rel_left_defending(rel_left_defending<0)),'o')
legend('Attacker pieces','Defender pieces')
ylabel('Fraction of pieces left')
xlabel('Number of Attackers : Number of Defenders')
title('Expected number of pieces left over after an attack')
xlim([0 10])
set(gca,'LineWidth',1.25)
set(gca,'FontSize',14)
savefig(fig2,sprintf('%s/Expected_leftover_pieces1.fig',my_dir))
print(fig2,sprintf('%s/Expected_leftover_pieces1.png',my_dir),'-dpng','-r300')

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
