#------------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 01_bw_figures.R
# Joanna Pepin
#------------------------------------------------------------------------------------

# FIGURE 1 ##########################################################################
fig1 <- ggplot(data_f1, aes(x = vals * prop, 
                            y = year, 
                            label = path,
                            fill = rev(path))) +
  geom_col(position = "stack") +
  geom_bar_text(data = . %>% filter(year == 2014), position = "stack", 
                reflow = TRUE, min.size = 4,size = 8, place = "center") +
  geom_text(aes(x = vals * prop, y = year, label = sprintf("%1.0f%%", 1*vals)),
            position = position_stack(vjust = .5), vjust = 4, color = "white", fontface = "bold") +
  geom_text(aes(total, year, label = sprintf("%1.0f%%", 1*prop), fill = NULL), hjust = -.2) +
  scale_fill_manual(values = c("#E2E2E2", "#C2C2C2", "#8A8A8A", "#474747", "#EF4868")) +
  theme_minimal() +
  theme(legend.position     = "none",
        axis.text.x         = element_blank(),
        axis.text.y         = element_text(face="bold"),
        panel.grid.major    = element_blank(), 
        panel.grid.minor    = element_blank(),
        plot.title.position = "plot",
        plot.margin         = margin(
          t = 0,    # Top margin
          r = 0,    # Right margin
          b = 0,    # Bottom margin
          l = 0)) + # Left margin
  scale_y_discrete(limits   = rev) +
  labs(title    = "Mothers' transition rate into primary-earning",
       subtitle = "by SIPP panel and pathway",
       x        = " ", 
       y        = " ")

fig1

ggsave(filename = file.path(figDir, "fig1.png"), fig1, width=6.5, height=3.5, units="in", dpi=300)


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
  labs(title = "Total amount of the growth in maternal primary-earning explained",
       subtitle = "by each pathway and disaggregated by demographic group",
       x    = " ", 
       y    = "% explained")
fig2

ggsave(filename = file.path(figDir, "fig2.png"), fig2, width=6, height=9, units="in", dpi=300)
