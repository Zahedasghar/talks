library(plotly)
library(reshape2)

# Cobb-Douglas parameters
A <- 1
alpha <- 0.3
beta <- 0.7

# Input ranges for capital (K) and labor (L)
K <- seq(1, 100, length.out = 100)
L <- seq(1, 100, length.out = 100)

# Create a grid of capital and labor values
grid <- expand.grid(K = K, L = L)

# Compute the production output Y based on Cobb-Douglas function
grid$Y <- A * (grid$K^alpha) * (grid$L^beta)

# Reshape the data for plotting
grid_melt <- acast(grid, K ~ L, value.var = "Y")

# Create interactive 3D plot
fig <- plot_ly(z = ~grid_melt, x = ~K, y = ~L, type = "surface")

# Customize layout
fig <- fig %>% layout(title = "Cobb-Douglas Production Function",
                      scene = list(xaxis = list(title = "Capital (K)"),
                                   yaxis = list(title = "Labor (L)"),
                                   zaxis = list(title = "Output (Y)")))

# Show the interactive plot
fig





library(plotly)
library(reshape2)

# Cobb-Douglas parameters with Decreasing Returns to Scale (DRS)
A <- 1
alpha <- 0.4  # Output elasticity of capital
beta <- 0.4   # Output elasticity of labor
# alpha + beta < 1 indicates decreasing returns to scale

# Input ranges for capital (K) and labor (L)
K <- seq(1, 100, length.out = 100)
L <- seq(1, 100, length.out = 100)

# Create a grid of capital and labor values
grid <- expand.grid(K = K, L = L)

# Compute the production output Y based on Cobb-Douglas function
grid$Y <- A * (grid$K^alpha) * (grid$L^beta)

# Reshape the data for plotting
grid_melt <- acast(grid, K ~ L, value.var = "Y")

# Create interactive 3D plot
fig <- plot_ly(z = ~grid_melt, x = ~K, y = ~L, type = "surface")

# Customize layout
fig <- fig %>% layout(title = "Cobb-Douglas Production Function (DRS)",
                      scene = list(xaxis = list(title = "Capital (K)"),
                                   yaxis = list(title = "Labor (L)"),
                                   zaxis = list(title = "Output (Y)")))

# Show the interactive plot
fig



## Indifference Curve

library(plotly)
library(reshape2)

# Utility Function parameters
alpha <- 0.5
beta <- 0.5
# U = X^alpha * Y^beta

# Input ranges for goods X and Y
X <- seq(1, 100, length.out = 100)
Y <- seq(1, 100, length.out = 100)

# Create a grid of X and Y values
grid <- expand.grid(X = X, Y = Y)

# Compute utility based on the Cobb-Douglas utility function
grid$Utility <- (grid$X^alpha) * (grid$Y^beta)

# Reshape data for plotting
grid_melt <- acast(grid, X ~ Y, value.var = "Utility")

# Create interactive 3D plot for the utility function
fig_utility <- plot_ly(z = ~grid_melt, x = ~X, y = ~Y, type = "surface")

# Customize layout for the utility function
fig_utility <- fig_utility %>% layout(title = "Cobb-Douglas Utility Function",
                                      scene = list(xaxis = list(title = "Good X"),
                                                   yaxis = list(title = "Good Y"),
                                                   zaxis = list(title = "Utility (U)")))

# Display the utility function plot
fig_utility


## Indifference Curve

# Set a fixed utility level for the indifference curve
U_fixed <- 500

# Compute the indifference curve by solving for Y given fixed utility U
grid$Indifference <- U_fixed / (grid$X^alpha)

# Remove any invalid values (e.g., negative or infinite values)
grid <- grid[grid$Indifference > 0 & is.finite(grid$Indifference), ]

# Create a 3D interactive plot for indifference curve
fig_indifference <- plot_ly(x = grid$X, y = grid$Indifference, z = U_fixed, type = "scatter3d", mode = "lines")

# Customize layout for indifference curve plot
fig_indifference <- fig_indifference %>% layout(title = "Indifference Curve",
                                                scene = list(xaxis = list(title = "Good X"),
                                                             yaxis = list(title = "Good Y"),
                                                             zaxis = list(title = "Utility (U)")))

# Display the indifference curve plot
fig_indifference
