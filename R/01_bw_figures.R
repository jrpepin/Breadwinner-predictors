#------------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 01_bw_figures.R
# Joanna Pepin
#------------------------------------------------------------------------------------


# Calculate percent change
pred <- data %>%
  group_by(year, label) %>%
  mutate(pre = dollars_adj[time == "Pre"],
         post = dollars_adj[time == "Post"],
         change = round(sum(dollars_adj[time == "Post"] -dollars_adj[time == "Pre"])/dollars_adj[time == "Pre"], 2),
         pre=scales::dollar(pre),
         post=scales::dollar(post))

### Convert to factor
cols <- c("category", "label", "time", "year")

pred[cols] <- lapply(pred[cols], factor) 
sapply(pred, class)


### Order categories

pred$category <- factor(pred$category, levels =c("Total", "Education", "Race"))
pred$time     <- factor(pred$time, levels =c("Pre", "Post"))
pred$label    <- factor(pred$label, levels =c("Total", "HS or Less", "Some College", "College Plus", 
                                              "NH White", "Black", "NH Asian", "Hispanic"))

levels(pred$label)[levels(pred$label)=="HS or Less"] <- "High School\nor Less"
levels(pred$category)[levels(pred$category)=="Race"] <- "Race-Ethnicity"
levels(pred$category)[levels(pred$category)=="Total"] <- "All Mothers"

pred$year2 = as.character(pred$year)
pred$year2[pred$year == "1996" & pred$label == "Black" ] = "1996 "

#--------------------------------------------------------------------------------------------
# % Change -- with category labels

dataA <- pred %>%
  select(label, change, year, year2, category) %>%
  unique()

levels(dataA$label)[levels(dataA$label)=="Total"] <- "     " # Removing for graphing

figA <- dataA %>%
ggplot(aes(x = label, y = change, fill = year2)) + 
  geom_col(width = 0.7, position   =  position_dodge(.8)) +
  facet_grid(~ category, scales    =  'free_x', space = "free") +
  geom_text(. %>% filter(category  == "All Mothers"), 
            mapping  = aes(label   =  year, 
            color    = year,
            y        = 0.015),
            position = position_dodge(.8),
            size     = 3,
            fontface = "bold") +
  geom_text(mapping  = aes(label=percent(change, accuracy = 2)), 
            position = position_dodge(width=0.8), 
            vjust    = 1.2,
            color    = "#000000",
            size     = 3) +
  geom_hline(yintercept = 0.0) +
  theme_minimal(12) +
  theme(# axis.text.x         = element_text(face = "bold"),
        strip.text.x        = element_text(face = "bold"),
        legend.position     = "none",
        panel.grid.minor.y  = element_blank(),
        text                = element_text(family="serif"),
        panel.spacing       = unit(2, "lines"),
        strip.placement     = 'outside') +
  scale_x_discrete(position = "top") +
  scale_y_continuous(limits = c(-0.45, .10), 
                     breaks = c(-.40, -.30, -.20, -.10, 0.0, .10), 
                     labels = c("-40%", "-30%", "-20%", "-10%", "No change", "10%")) +
  scale_fill_manual(values  = c("#ff4e50", "#999999", "#b83c30")) +
  scale_color_manual(values = c("#ff4e50", "#b83c30", "#999999")) +
      labs( x      = " ", 
          y        = " ", 
          fill     = " ",
          color    = " ",
          title    = "Percentage change in median household income upon mothers' transition to primary-earning status",
          subtitle = "by mothers' education level and race/ethnicity")

figA

ggsave(plot = figA, path = figDir, filename = "figA.png", dpi = 300, height = 5, width = 9)


#--------------------------------------------------------------------------------------------
# % Change -- without category labels

dataAA <- pred %>%
  select(label, change, year, year2, category) %>%
  unique()

levels(dataAA$label)[levels(dataAA$label)=="Total"] <- "All Mothers"


figAA <- dataAA %>%
  ggplot(aes(x = label, y = change, fill = year2)) + 
  geom_col(width = 0.7, position   =  position_dodge(.8)) +
  facet_grid(~ category, scales    =  'free_x', space = "free") +
  geom_text(. %>% filter(category  == "All Mothers"), 
            mapping  = aes(label   =  year, 
                           color    = year,
                           y        = 0.015),
            position = position_dodge(.8),
            size     = 3,
            fontface = "bold") +
  geom_text(mapping  = aes(label=percent(change, accuracy = 2)), 
            position = position_dodge(width=0.8), 
            vjust    = 1.2,
            color    = "#000000",
            size     = 3) +
  geom_hline(yintercept = 0.0) +
  theme_minimal(12) +
  theme(axis.text.x         = element_text(face = "bold"),
        legend.position     = "none",
        panel.grid.minor.y  = element_blank(),
        text                = element_text(family="serif"),
        panel.spacing       = unit(2, "lines"),
        strip.text.x        = element_blank()) +
  scale_x_discrete(position = "top") +
  scale_y_continuous(limits = c(-0.45, .10), 
                     breaks = c(-.40, -.30, -.20, -.10, 0.0, .10), 
                     labels = c("-40%", "-30%", "-20%", "-10%", "No change", "10%")) +
  scale_fill_manual(values  = c("#ff4e50", "#999999", "#b83c30")) +
  scale_color_manual(values = c("#ff4e50", "#b83c30", "#999999")) +
  labs( x      = " ", 
        y        = " ", 
        fill     = " ",
        color    = " ",
        title    = "Percentage change in median household income upon mothers' transition to primary-earning status",
        subtitle = "by mothers' education level and race/ethnicity")

figAA

ggsave(plot = figAA, path = figDir, filename = "figAA.png", dpi = 300, height = 5, width = 9)


#--------------------------------------------------------------------------------------------
# $ Change

dataB <- pred %>%
  select(label, year, time, category, dollars_adj) %>%
  unique()

levels(dataB$time)[levels(dataB$time)=="Pre"]  <- "Before\ntransition"
levels(dataB$time)[levels(dataB$time)=="Post"] <- "After\ntransition"
levels(dataB$label)[levels(dataB$label)=="Total"] <- "All Mothers"


figB <- ggplot(dataB,
       aes(time, dollars_adj, 
           fill  = year, 
           color = year, 
           group = interaction(label, year))) +
  geom_line(size = 1.2) +
  geom_point(size = 3.5, shape=21) +
  geom_text(. %>% filter(category  == "All Mothers" & time == "After\ntransition"), 
            mapping  = aes(label    = year, 
                           color    = year,
                           fontface = "bold",
                           hjust    = -.4),
                           size     = 3) +
  facet_wrap(~label, ncol = 4) +
  theme_minimal() +
  theme(strip.text.x         = element_text(face = "bold"),
        legend.position     = "none",
        panel.grid.minor.y  = element_blank(),
        text                = element_text(family="serif")) +
  scale_y_continuous(labels = scales::dollar_format()) +
  scale_fill_manual(values  = c("#ff4e50", "#b83c30")) +
  scale_color_manual(values = c("#ff4e50", "#b83c30")) +
  labs( x        = " ", 
        y        = " ", 
        fill     = " ",
        color    = " ",
        title    = "Change in median household income upon mothers' transition to primary-earning status",
        subtitle = "by mothers' education level and race/ethnicity",
        caption  = "Note: 2014 inflation-adjusted dollars")

figB
ggsave(plot = figB, path = figDir, filename = "figB.png", dpi = 300, height = 5, width = 7.5)
