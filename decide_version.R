decideAppVersion <- function() {
  
  # loading relevant reward_history
  reward_history = s3read_using(FUN = read.csv, object = "s3://bidm-bucket/reward_history.csv") %>% select(-X)
  
  # calculating UCB metric
  ucb_max = reward_history %>% 
    group_by(version) %>% 
    summarise(steps = n(),
              ucb = sum(reward)/steps + sqrt((2 * log(nrow(reward_history))) / steps)) %>% 
    filter(ucb == max(ucb)) 
  
  print(ucb_max)
  
  # random arm if rewards are equal (1st step)
  if (nrow(ucb_max)>1) {
    return(sample(c("control", "test"), 1))
  } else {
    return(ucb_max %>% select(version) %>% as.character())
  }
}