load("data/38837-0001-Data.rda")   # creates the object da38837.0001
dir.create("Images/Model", recursive = TRUE, showWarnings = FALSE)

#===============================
# MIDUS Sleep-HRV Study Dataset
#===============================
library(tidyverse)

outcome_vars <- c(
  "C4VB2LRM"
)

sleep_vars <- c(
  "C4S2",
  "C4S4",
  "C4S5",
  "C4S7",
  
  "C4S9A",
  "C4S9B",
  "C4S9C",
  "C4S9D",
  "C4S9E",
  "C4S9F",
  "C4S9G",
  "C4S9H",
  "C4S9I",
  "C4S9J"
)


modifier_vars <- c(
  "C1PRSEX",
  "C4ZAGE"
)


metabolic_vars <- c(
  "C4PBMI"
)


alcohol_vars <- c(
  "C4H51",
  "C4H1U",
  "C4H75G1",
  "C4H75G2",
  "C4H75G4"
)

id_vars <- c(
  "M2ID"
)

analysis_vars <- c(
  outcome_vars,
  sleep_vars,
  modifier_vars,
  metabolic_vars,
  alcohol_vars
)

# Add ID
analysis_vars <- c(
  id_vars,
  analysis_vars
)

# check variables

variable_check <- data.frame(
  Variable = analysis_vars,
  Available = analysis_vars %in% names(da38837.0001)
)

print(variable_check)
# create analytical dataset

MIDUS_sleep_HRV <- da38837.0001 %>%
  select(
    all_of(
      analysis_vars[
        analysis_vars %in% names(da38837.0001)
      ]
    )
  )


# dimensions
dim(MIDUS_sleep_HRV)

# save
saveRDS(
  MIDUS_sleep_HRV,
  "MIDUS_sleep_HRV_analysis_dataset.rds"
)

head(MIDUS_sleep_HRV, 10)

# ============================================================
# SECTION 2: Missing Data Assessment and Dataset Cleaning
# ============================================================

missing_summary <- MIDUS_sleep_HRV %>%
  summarise(
    across(
      everything(),
      ~sum(is.na(.))
    )
  ) %>%
  
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Missing_Count"
  ) %>%
  
  mutate(
    Missing_Percent = 
      round(
        Missing_Count / nrow(MIDUS_sleep_HRV) * 100,
        2
      )
  ) %>%
  
  arrange(desc(Missing_Percent))

missing_summary

write.csv(
  missing_summary,
  "MIDUS_missing_summary.csv",
  row.names = FALSE
)
missing_threshold <- 40
removed_variables <- missing_summary %>%
  filter(
    Missing_Percent > missing_threshold
  ) %>%
  pull(Variable)

removed_variables

MIDUS_sleep_HRV_clean_vars <- MIDUS_sleep_HRV %>%
  select(
    -all_of(removed_variables)
  )
dim(MIDUS_sleep_HRV_clean_vars)

MIDUS_sleep_HRV_clean <- MIDUS_sleep_HRV_clean_vars %>%
  drop_na()

cleaning_report <- data.frame(
  
  Step = c(
    "Original dataset",
    "After removing variables",
    "Final complete-case dataset"
  ),
  
  Participants = c(
    nrow(MIDUS_sleep_HRV),
    nrow(MIDUS_sleep_HRV_clean_vars),
    nrow(MIDUS_sleep_HRV_clean)
  ),
  
  Variables = c(
    ncol(MIDUS_sleep_HRV),
    ncol(MIDUS_sleep_HRV_clean_vars),
    ncol(MIDUS_sleep_HRV_clean)
  )
)


cleaning_report

# ------------------------------------------------------------
# Save Clean Dataset
# ------------------------------------------------------------
saveRDS(
  MIDUS_sleep_HRV_clean,
  "MIDUS_sleep_HRV_clean.rds"
)

#####################################################
################ Expl./Res Data Analysis ##########
#####################################################

# Create output directory
if(!dir.exists("Images/EDA")){
  dir.create("Images/EDA", recursive = TRUE)
}

# Dataset overview
dim(MIDUS_sleep_HRV_clean)
str(MIDUS_sleep_HRV_clean)
summary(MIDUS_sleep_HRV_clean)


## Automatically detect response variable

candidate_response <- c(
  "C4VB2LRM",
  "HRV"
)

response_var <-
  candidate_response[
    candidate_response %in%
      names(MIDUS_sleep_HRV_clean)
  ][1]

if(is.na(response_var)){
  
  stop(
    "Response variable was not found."
  )
  
}

cat("\n")
cat("Response Variable:",response_var,"\n\n")


# Variable Groups 
continuous_vars <- c(
  
  "C4S2",
  "C4S4",
  "C4ZAGE",
  "C4PBMI"
  
)

ordinal_vars <- c(
  
  "C4S5",
  "C4S7",
  
  "C4S9A",
  "C4S9B",
  "C4S9C",
  "C4S9D",
  "C4S9E",
  "C4S9F",
  "C4S9G",
  "C4S9H",
  "C4S9I",
  "C4S9J",
  
  "C4H51",
  "C4H1U"
  
)

binary_vars <- c(
  
  "C1PRSEX"
  
)

# Keep Existing Variables 
continuous_vars <-
  continuous_vars[
    continuous_vars %in%
      names(MIDUS_sleep_HRV_clean)
  ]

ordinal_vars <-
  ordinal_vars[
    ordinal_vars %in%
      names(MIDUS_sleep_HRV_clean)
  ]

binary_vars <-
  binary_vars[
    binary_vars %in%
      names(MIDUS_sleep_HRV_clean)
  ]

# Check Variable Classes 
variable_info <-
  data.frame(
    Variable=
      c(
        response_var,
        continuous_vars,
        ordinal_vars,
        binary_vars
      ),
    Class=
      sapply(
        MIDUS_sleep_HRV_clean[
          c(
            response_var,
            continuous_vars,
            ordinal_vars,
            binary_vars
          )
        ],
        class
      )
  )
print(variable_info)

# Response Variable 
response_data <-
  as.numeric(
    MIDUS_sleep_HRV_clean[[response_var]] 
  )
summary(response_data)
sd(response_data)
shapiro.test(response_data)

# Histogram
png(
  "Images/EDA/response_histogram.png",
  width=1200,
  height=800
)

hist(
  response_data,
  main=paste("Distribution of",response_var),
  xlab=response_var,
  probability=TRUE
)
lines( 
  density(response_data),
  lwd=2
)
dev.off()

# Density
png(
  "Images/EDA/response_density.png",
  width=1200,
  height=800
)

plot(
  density(response_data),
  main=paste("Density of",response_var),
  xlab=response_var,
  lwd=2
)

dev.off()
# QQ
png(
  "Images/EDA/response_qqplot.png",
  width=1200,
  height=800
)
qqnorm(
  response_data,
  main=paste("Q-Q Plot:",response_var)
)
qqline(response_data)
dev.off()

# Boxplot
png(
  "Images/EDA/response_boxplot.png",
  width=1200,
  height=800
)

boxplot(
  response_data,
  main=paste("Boxplot:",response_var),
  ylab=response_var
)

dev.off()

#####################################################
############ Association Analysis ###################
#####################################################

response_var <- "HRV"
continuous_vars <- c(
  "C4S2",
  "C4S4",
  "C4ZAGE",
  "C4PBMI"
)

ordinal_vars <- c(
  "C4S5",
  "C4S7",
  "C4S9A",
  "C4S9B",
  "C4S9C",
  "C4S9D",
  "C4S9E",
  "C4S9F",
  "C4S9G",
  "C4S9H",
  "C4S9I",
  "C4S9J",
  "C4H51",
  "C4H1U"
)

binary_vars <- c(
  "C1PRSEX"
)

# Pearson Correlation

response_var <- "C4VB2LRM"
pearson_results <-
  data.frame()

for(var in continuous_vars){
  
  x <- MIDUS_sleep_HRV_clean[[var]]
  y <- MIDUS_sleep_HRV_clean[[response_var]]
  
  cor_test <- cor.test(
    x,
    y,
    method = "pearson"
  )
  
  pearson_results <-
    rbind(
      pearson_results,
      data.frame(
        Variable = var,
        Correlation = cor_test$estimate,
        P_value = cor_test$p.value
      )
    )
  
  png(
    paste0(
      "Images/EDA/pearson_",
      var,
      ".png"
    ),
    width=1200,
    height=800
  )
  
  plot(
    x,
    y,
    pch=19,
    xlab=var,
    ylab=response_var,
    main=paste("HRV vs",var)
  )
  
  abline(
    lm(y~x),
    lwd=2
  )
  
  dev.off()
  
}

pearson_results

# Spearman Correlation

spearman_results <-
  data.frame()

for(var in ordinal_vars){
  
  x <-
    as.numeric(
      MIDUS_sleep_HRV_clean[[var]]
    )
  
  y <-
    MIDUS_sleep_HRV_clean[[response_var]]
  
  cor_test <-
    cor.test(
      x,
      y,
      method="spearman",
      exact=FALSE
    )
  
  spearman_results <-
    rbind(
      spearman_results,
      data.frame(
        Variable=var,
        Correlation=cor_test$estimate,
        P_value=cor_test$p.value
      )
    )
  
  png(
    paste0(
      "Images/EDA/spearman_",
      var,
      ".png"
    ),
    width=1200,
    height=800
  )
  
  boxplot(
    y~MIDUS_sleep_HRV_clean[[var]],
    xlab=var,
    ylab=response_var,
    main=paste("HRV by",var)
  )
  
  dev.off()
  
}

spearman_results

# Binary Variables

binary_results <-
  data.frame()

for(var in binary_vars){
  
  model <-
    t.test(
      MIDUS_sleep_HRV_clean[[response_var]] ~
        MIDUS_sleep_HRV_clean[[var]]
    )
  
  binary_results <-
    rbind(
      binary_results,
      data.frame(
        Variable=var,
        P_value=model$p.value
      )
    )
  
  png(
    paste0(
      "Images/EDA/boxplot_",
      var,
      ".png"
    ),
    width=1200,
    height=800
  )
  
  boxplot(
    MIDUS_sleep_HRV_clean[[response_var]]~
      MIDUS_sleep_HRV_clean[[var]],
    xlab=var,
    ylab=response_var,
    main=paste("HRV by",var)
  )
  
  dev.off()
  
}

binary_results

# Correlation Matrix

numeric_data <-
  MIDUS_sleep_HRV_clean[
    c(
      response_var,
      continuous_vars
    )
  ]

cor_matrix <-
  cor(
    numeric_data,
    use="complete.obs"
  )

write.csv(
  cor_matrix,
  "Images/EDA/correlation_matrix.csv"
)

png(
  "Images/EDA/correlation_heatmap.png",
  width=1400,
  height=1200
)

heatmap(
  cor_matrix,
  symm=TRUE
)

dev.off()

# Save Results

write.csv(
  pearson_results,
  "Images/EDA/pearson_results.csv",
  row.names=FALSE
)

write.csv(
  spearman_results,
  "Images/EDA/spearman_results.csv",
  row.names=FALSE
)

write.csv(
  binary_results,
  "Images/EDA/binary_results.csv",
  row.names=FALSE
)


#####################################################
############ Multiple Linear Regression #############
#####################################################


analysis_data <- MIDUS_sleep_HRV_clean

factor_vars <- c(
  "C4S5",
  "C4S7",
  "C4S9A",
  "C4S9B",
  "C4S9C",
  "C4S9D",
  "C4S9E",
  "C4S9F",
  "C4S9G",
  "C4S9H",
  "C4S9I",
  "C4S9J",
  "C1PRSEX",
  "C4H51",
  "C4H1U"
)

analysis_data[factor_vars] <-
  lapply(
    analysis_data[factor_vars],
    factor
  )

#####################################################
# Full Model
#####################################################

full_model <-
  lm(
    
    C4VB2LRM ~
      
      C4S2 +
      C4S4 +
      C4S5 +
      C4S7 +
      
      C4S9A +
      C4S9B +
      C4S9C +
      C4S9D +
      C4S9E +
      C4S9F +
      C4S9G +
      C4S9H +
      C4S9I +
      C4S9J +
      
      C1PRSEX +
      C4ZAGE +
      C4PBMI +
      C4H51 +
      C4H1U,
    
    data = analysis_data
    
  )

# Summary
summary(full_model)

# ANOVA
anova(full_model)


#####################################################
####### Backward Elimination Model Selection ########
#####################################################

full_model <- lm(
  
  C4VB2LRM ~
    C4S2 +
    C4S4 +
    C4S5 +
    C4S7 +
    C4S9A +
    C4S9B +
    C4S9C +
    C4S9D +
    C4S9E +
    C4S9F +
    C4S9G +
    C4S9H +
    C4S9I +
    C4S9J +
    C1PRSEX +
    C4ZAGE +
    C4PBMI +
    C4H51 +
    C4H1U,
  
  data = analysis_data
  
)


backward_model <- step(
  
  full_model,
  
  direction = "backward",
  
  trace = TRUE
  
)

# Final Model Summary
summary(backward_model)
anova(backward_model)

# Formula
formula(backward_model)

# Coefficients
coef(backward_model)

# Save model
saveRDS(
  backward_model,
  "backward_model.rds"
)

# Final Model Diagnostic 
png(
  
  "Images/Model/final_model_diagnostics.png",
  
  width = 1600,
  
  height = 1600
  
)
par(
  mfrow = c(2,2)
)
plot(backward_model)
dev.off()


#####################################################
############ Regression Assumption Checking #########
#####################################################


# Load required package

if(!require(car)){
  install.packages("car")
  library(car)
}

# Residual Analysis
residuals_model <- residuals(backward_model)
fitted_values <- fitted(backward_model)
summary(residuals_model)


# Normality Test of Residuals
shapiro_test <- shapiro.test(
  residuals_model
)
shapiro_test

# Q-Q Plot of Residuals

png(
  "Images/Model/residual_qqplot.png",
  width = 1200,
  height = 900
)
qqnorm(
  residuals_model,
  main = "Q-Q Plot of Residuals"
)
qqline(
  residuals_model,
  lwd = 2
)

dev.off()



# Residuals vs Fitted Plot

png(
  "Images/Model/residuals_vs_fitted.png",
  width = 1200,
  height = 900
)


plot(
  fitted_values,
  residuals_model,
  xlab = "Fitted Values",
  ylab = "Residuals",
  main = "Residuals vs Fitted Values",
  pch = 19
)


abline(
  h = 0,
  lwd = 2
)


dev.off()



# Breusch-Pagan Test
# Homoscedasticity
if(!require(lmtest)){
  install.packages("lmtest")
  library(lmtest)
}


bp_test <- bptest(
  backward_model
)


bp_test

# Multicollinearity Check
vif_values <- vif(
  backward_model
)


vif_values


# Cook's Distance
cook_values <- cooks.distance(
  backward_model
)
summary(cook_values)

png(
  "Images/Model/cooks_distance.png",
  width = 1200,
  height = 900
)

plot(
  cook_values,
  type="h",
  main="Cook's Distance",
  ylab="Distance",
  xlab="Observation"
)

abline(
  h = 4/nrow(analysis_data),
  lwd = 2
)

dev.off()



# Detect influential observations

influential_points <- which(
  cook_values > 4/nrow(analysis_data)
)


influential_points

# Save diagnostic results
saveRDS(
  list(
    shapiro = shapiro_test,
    breusch_pagan = bp_test,
    vif = vif_values,
    cooks_distance = cook_values
  ),
  "model_diagnostics_results.rds"
)


#####################################################
############ Final Model Detailed Results ############
#####################################################


# Model summary
summary(backward_model)
# Confidence intervals
confint(backward_model)
# Model coefficients table
coef_table <- summary(backward_model)$coefficients
coef_table

# Standardized coefficients
library(lm.beta)
standardized_model <- lm.beta(backward_model)
summary(standardized_model)
# Predicted vs observed values
prediction_data <- data.frame(
    Observed = analysis_data$C4VB2LRM,
  Predicted = fitted(backward_model)
)

head(prediction_data)


# RMSE

rmse <- sqrt(
  mean(
    (prediction_data$Observed -
       prediction_data$Predicted)^2
  )
)
rmse
# Mean and SD of response variable
mean_response <- mean(
  analysis_data$C4VB2LRM
)
sd_response <- sd(
  analysis_data$C4VB2LRM
)

mean_response
sd_response

# Number of observations
nobs(backward_model)
table(
  analysis_data$C4S9H
)
