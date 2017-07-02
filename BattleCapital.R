# choose your settings
di_range <- 1:6 # faces of the die
def_vec <- 1:15 # vector of number of defenders to be used in simulations
attack_vec <- 1:15 # vector of number of attackers to be used in simulations
num_its <- 10000 # number of simulations to run for each N-defenders vs N-attackers situation.

Y <- matrix(0,length(def_vec),length(attack_vec))
Z <- matrix(0,length(def_vec),length(attack_vec))
lost_attackers <- matrix(0,length(def_vec),length(attack_vec))
rel_left_attacking <- matrix(0,length(def_vec),length(attack_vec))
rel_left_defending <- matrix(0,length(def_vec),length(attack_vec))

boo <- 1:length(def_vec)

# I was able to parallelize this for loop quite easily in matlab, but in R it is a bit trickier, so I didn't bother.
# Plus, I only have 2 cores on my mac...so its not like there is a huge performance gain.
# But, if you have many cores, this is an obvious thing to parallelize.
# Note that when you parallelize, you usually can't index by both k and j (e.g. that is why there is a k_foo variable)
# I added rel_left_attacking[j,k] into the loop, but to parallelize, it would need to be brought outside.
for (k in boo) {
    k_foo <- c()
    left_foo <- c()
    for (j in 1:length(attack_vec)) {
        goo <- c()
        for (c in 1:num_its) {
            num_defense <- def_vec[k]
            num_attack <- attack_vec[j]
            # the output of FinalDiff is "Number of Attackers Left - Number of Defenders Left"
            # when it is negative, defenders win (and there are abs(goo[c]) defenders left)
            # when it is positive, attackers win (and there are goo[c] attackers left)
            goo[c] <- FinalDiff(num_attack,num_defense,di_range)
        }
        k_foo[j] <- sum(goo>0)/num_its
        left_foo[j] <- mean(goo)
        rel_left_attacking[j,k] <- mean(goo)/num_attack
        rel_left_defending[j,k] <- mean(goo)/num_defense
        Z[j,k] <- num_attack/num_defense
    }
    Y[,k] <- k_foo
}

# easier to just unlist this stuff into two paired vectors, rather than deal with 2 indices
attack_ratio <- as.vector(Z)
attack_success_rate <- as.vector(Y)

# eh, lets just use base R graphics for this part
png('Probability_of_Successful_Capital_Attack.png')
plot(attack_ratio,attack_success_rate,
     main='Likelihood of winning an attack on a capital',
     xlab = 'Number of Attackers : Number of Defenders',
     ylab = 'Probability of Attack Succeeding',
     xlim = c(0,5)
)
dev.off()

# ##
# make the thing into a data frame so i can use ggplot
dfa <- data.frame(attack_ratio = attack_ratio[rel_left_attacking>0],
                  fraction_pieces_left = rel_left_attacking[rel_left_attacking>0],
                  type = 'Attackers')
dfb <- data.frame(attack_ratio = attack_ratio[rel_left_defending<0],
                  fraction_pieces_left = abs(rel_left_defending[rel_left_defending<0]),
                  type = 'Defenders')
df <- rbind(dfa,dfb)

png('Expected_leftover_pieces.png')
p <- ggplot(df, aes(attack_ratio,fraction_pieces_left , colour = type))
p + geom_point() + 
  ylab('Fraction of pieces left') + 
  xlab('Number of Attackers : Number of Defenders') + 
  ggtitle('Expected number of pieces left over after an attack') + 
  xlim(c(0,10))
dev.off()

## FUNCTIONS
FinalDiff <- function(num_attack,num_defense,di_range){
while ((num_attack > 0) && (num_defense > 0)) {
    output <- fooBattleCapital(num_attack,num_defense,di_range)
    num_attack <- output[[1]]
    num_defense <- output[[2]]
    #     fprintf('Number of attackers left: %d \n',num_attack)
    #     fprintf('Number of defenders left: %d \n',num_defense)
}
foo_diff <- num_attack - num_defense
return(foo_diff)
}

fooBattleCapital <- function(num_attack,num_defense,di_range) {
if (num_attack==0 || num_defense==0) {
    return(num_attack,num_defense)
}
attack_losses <- 0
defense_losses <- 0

n_attack_dice <- min(num_attack,3)
n_defense_dice <- min(num_defense,2)

attack_rolls <- sort.int(sample(di_range,n_attack_dice,replace=T),decreasing=TRUE)
defense_rolls <- sort.int(sample(di_range,n_defense_dice,replace=T),decreasing=TRUE)

# fprintf('Attack rolled: %s \n',strjoin(string(attack_rolls)))
# fprintf('Defense rolled: %s \n',strjoin(string(defense_rolls)))

di_attack <- 1
di_defense <- 1
while ((di_attack <= n_attack_dice) && (di_defense <= n_defense_dice)) {
    best_attack <- attack_rolls[di_attack]
    best_defense <- defense_rolls[di_defense]
    if ((best_defense + 1) >= best_attack) {
        attack_losses <- attack_losses + 1
    }
    else {
        defense_losses <- defense_losses + 1
    }
    di_attack <- di_attack + 1
    di_defense <- di_defense + 1
}

# fprintf('Attack loses: %s \n',strjoin(string(attack_losses)))
# fprintf('Defense loses: %s \n',strjoin(string(defense_losses)))

num_attack <- num_attack - attack_losses
num_defense <- num_defense - defense_losses

output <- list(num_attack,num_defense)
return(output)

}
