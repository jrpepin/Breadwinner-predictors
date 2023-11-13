#------------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 01_bw_figures.R
# Joanna Pepin
#------------------------------------------------------------------------------------

# Wrangle data ######################################################################
names(data_f1)

data_f1 <- data_f1 %>% 
  rename("inc_pre"      = "income pre",
         "inc_post"     = "income post",
         "ratio_pre"    = "income/ needs pre",
         "ratio_post"   = "income / needs post",
         "inc_change"   = "Income Change",
         "ratio_change" = "Income / Needs Change") %>%
  select("SSUID", "inc_pre", "inc_post", "inc_change", "ratio_pre", "ratio_post", "ratio_change")

data_f1 %>% 
  mutate(positive_inc=(inc_change>=0),
         negative_inc=(inc_change<0)) %>%
  summarise(pct_positive_inc = 100*mean(positive_inc),
            pct_negative_inc = 100*mean(negative_inc))
  
# long format
library(tidyr)
d1 <- data_f1 %>%
  select(SSUID, inc_pre, inc_post) %>%
  pivot_longer(
    cols = starts_with("inc"),
    names_to = "time",
    names_prefix = "inc",
    values_to = "income",
    values_drop_na = TRUE) %>%
  mutate(time = case_when(
    time == "_pre" ~ "Pre",
    time == "_post" ~ "Post"))

d1$time <- factor(d1$time, levels = c("Post", "Pre"), ordered = FALSE)

d2 <- data_f1 %>%
  select(SSUID, ratio_pre, ratio_post) %>%
  pivot_longer(
    cols = starts_with("ratio"),
    names_to = "time",
    names_prefix = "ratio",
    values_to = "ratio",
    values_drop_na = TRUE) %>%
  mutate(time = case_when(
    time == "_pre" ~ "Pre",
    time == "_post" ~ "Post"))

d2$time <- factor(d2$time, levels = c("Post", "Pre"), ordered = FALSE)

dd <- data_f1 %>%
  pivot_longer(
    cols = !SSUID,
    names_to = c("type", "time"),
    names_sep = "_",
    values_to = "vals",
    values_drop_na = TRUE)

# FIGURE 1 ##########################################################################

p1<- data_f1 %>%
  ggplot() +
  geom_histogram(aes(x=inc_change, y = stat(width*density), fill = inc_change >= -2200),
                 color="#e9ecef",
                 alpha=0.5) +
  geom_vline(aes(xintercept = median(inc_change)), 
             linetype = "dashed", size = 0.6,
             color = "#000000") +
  xlim(c((-1.5*IQR(data_f1$inc_change)), (2.5*IQR(data_f1$inc_change)))) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("#B3697A", "#69b3a2")) +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.minor.y = element_blank()) +
  labs(title = "Household income",
       subtitle = "$ change in year transition to BW",
       x    = " ",
       y    = " ")
p1

p2<- data_f1 %>%
  ggplot() +
  geom_histogram(aes(x=ratio_change, y = stat(width*density), fill = ratio_change >= -.12),
                 color="#e9ecef",
                 alpha=.5) +
  geom_vline(aes(xintercept = median(ratio_change)), 
             linetype = "dashed", size = 0.6,
             color = "#000000") +
  xlim(c(-1.5*IQR(data_f1$ratio_change), 2.5*IQR(data_f1$ratio_change))) +
  scale_y_continuous(labels = percent_format(), limits = c(0, .25)) +
  scale_fill_manual(values = c("#B3697A", "#69b3a2")) +
  theme_minimal() +
  theme(legend.position = "none",
        panel.grid.minor.y = element_blank()) +
  labs(title = "Poverty threshold (1.5x)",
       subtitle = "Ratio change in year transition to BW",
       x    = " ",
       y    = " ")
p2


library(ggridges)
library(patchwork)

p3 <- d1 %>% 
  ggplot(aes(x = income, y  = time, fill = time)) + 
  stat_density_ridges(scale = 3,
                      quantile_lines = TRUE,
                      quantiles = 2,
                      alpha = .5) +
  geom_text(data=d1 %>% group_by(time) %>% 
              summarise(income=median(income)),
            aes(label=sprintf("%1.0f", income)), 
            position=position_nudge(y=-0.1), colour="black", size=3.5) +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_manual(values=c("#404080", "#a3a5a7")) +
  scale_x_continuous(limits =  c(0, 2.5*IQR(d1$income))) +
  labs(title = " ",
       subtitle = "Distribution pre and post transition to BW",
       x    = " ",
       y    = " ")
p3  


p4 <- d2 %>% 
  ggplot(aes(x = ratio, y  = time, fill = time)) + 
  geom_density_ridges(scale = 3,
                      quantile_lines = TRUE,
                      quantiles = 2,
                      alpha = .5) +
  geom_text(data=d2 %>% group_by(time) %>% 
              summarise(ratio=median(ratio)),
            aes(label=sprintf("%1.2f", ratio)), 
            position=position_nudge(y=-0.1), colour="black", size=3.5) +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_manual(values=c("#404080", "#a3a5a7")) +
  scale_x_continuous(limits =  c(0, 2.5*IQR(d2$ratio))) +
  labs(title = " ",
       subtitle = " ",
       x    = " ",
       y    = " ",
       caption =  "figures truncated due to long tails")
p4  

(p1 + p2)/ (p3 + p4)


data_f1 %>%
  ggplot() +
  geom_histogram(aes(x=inc_pre, y = stat(width*density)),
                 fill="#69b3a2",
                 color="#e9ecef",
                 alpha=0.5) +
  geom_histogram(aes(x=inc_post, y = stat(width*density)),
                 fill="#b3a269",
                 color="#e9ecef",
                 alpha=0.5) +
  geom_vline(aes(xintercept = median(inc_pre)), 
             linetype = "dashed", size = 0.6,
             color = "#69b3a2") +
  geom_vline(aes(xintercept = median(inc_post)), 
             linetype = "dashed", size = 0.6,
             color = "#b3a269") +  
  scale_x_continuous(limits =  c(0, 60000)) +
  scale_y_continuous(limits = c(0, .1),
                     labels = percent_format()) +
  theme_minimal() +
  labs(title = "Household income change upon transition to BW",
       x    = " ",
       y    = " ",
       caption =  "Figure truncated at 1.5 IQR change in income due to long tails")



data_f1 %>%
  ggplot() +
  geom_density(aes(x=inc_pre),
                 fill="#00AFBB",
                 color="#000000",
                 alpha=0.5) +
  geom_density(aes(x=inc_post),
                 fill="#E7B800",
                 color="#000000",
                 alpha=0.5) +
  scale_x_continuous(limits =  c(0, 60000)) +
  theme_minimal()





# panel B
data_f1 %>%
  ggplot() +
  geom_histogram(aes(x = inc_pre,  y = stat(width*density)),  fill="#69b3a2", color="#e9ecef", ) +
  geom_histogram(aes(x = inc_post, y = stat(width*-..density..)), fill= "#404080", color="#e9ecef",) +
 # xlim(0, 1.5*IQR(data_f1$inc_pre)) +
  scale_x_continuous(limits =  c(0, 1.5*IQR(data_f1$inc_pre))) +
  scale_y_continuous(limits = c(-.10,.10),
                     labels = percent_format())


data_f1 %>%
  ggplot() +
  geom_density(aes(x = inc_pre),  fill="#69b3a2", color="#e9ecef") +
  geom_density(aes(x = inc_post), fill= "#404080", color="#e9ecef", alpha=.5) +
  geom_vline(aes(xintercept = median(inc_pre)), 
             linetype = "dashed", size = 0.6,
             color = "#69b3a2") +
  geom_vline(aes(xintercept = median(inc_post)), 
             linetype = "dashed", size = 0.6,
             color = "#b3a269") +  
  scale_x_continuous(limits =  c(0, 1.5*IQR(data_f1$inc_pre))) 









# FIGURE 2 ##########################################################################

# Wrangle the data ------------------------------------------------------------------

data_f2$group <- factor(data_f2$group, 
                        levels = c("Hispanic", "NH Asian", "Black", "NH White", "  ",
                                   "College Plus", "Some College",  "HS Degree or Less", " ",
                                   "Total"), ordered = FALSE)

data_f2$event <- factor(data_f2$event, 
                        levels = c("Partner separation",
                                   "Mothers earnings increased", "Partners earnings decreased",
                                   "Mothers earnings increased & partners earnings decreased",
                                   "Other"), ordered = FALSE)

levels(data_f2$event)[levels(data_f2$event)=="Mothers earnings increased & partners earnings decreased"] <- "Mothers earnings increased & \npartners earnings decreased"


# Create Figure  ------------------------------------------------------------------

fig2 <- ggplot(data_f2, aes(x=group, y=vals)) +
  geom_segment( aes(x=group, xend=group, y=0, yend=vals), color="#474747") +
  geom_point( aes(color=event), size=3) +
  facet_grid(rows   = vars(event), 
             switch = "y") +
  theme_minimal() +
  coord_flip() +
  scale_color_manual(values = c("#EF4868", "#474747", "#8A8A8A", "#C2C2C2", "#E2E2E2")) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_x_discrete(drop=FALSE) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    panel.spacing = unit(1.2, "lines"),
    axis.ticks.y = element_blank(),
    legend.position = "none",
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, face = "bold"),
    plot.title.position = "plot") +
  geom_hline(yintercept=0) +
  labs(# title = "Total amount of the growth in maternal primary-earning explained",
       # subtitle = "by each pathway and disaggregated by demographic group",
       x    = " ", 
       y    = "% explained")
fig2

ggsave(filename = file.path(figDir, "fig2.png"), fig2, width=6, height=9, units="in", dpi=300)
