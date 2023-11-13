#-------------------------------------------------------------------------------
# BW PREDICTORS PROJECT
# 01_bw_figures.R
# Joanna Pepin
#-------------------------------------------------------------------------------

# FIGURE 1 #####################################################################

## Wrangle the data ------------------------------------------------------------
data_f1 <- data_f1 %>%
  mutate(total = prop*100,
         vals  = vals*100)

data_f1$year <- factor(data_f1$year, levels = c("2014", "1996"), ordered = FALSE)
data_f1$path <- factor(data_f1$path, 
                       levels = c("Partner separation", 
                                  "Mothers increased earnings",
                                  "Partner lost earnings", 
                                  "Mothers increased earnings & partner lost earnings",
                                  "Other member exit or lost earnings"), 
                       ordered = FALSE)

## Create Figure  --------------------------------------------------------------
fig1 <- ggplot(data_f1, aes(x = vals * prop, 
                            y = year, 
                            label = path,
                            fill = rev(path))) +
  geom_col(position = "stack") +
  geom_bar_text(data = . %>% filter(year == 2014), position = "stack", 
                reflow = TRUE, min.size = 4, size = 8, place = "center") +
  geom_text(aes(x = vals * prop, y = year, label = sprintf("%1.0f%%", 1*vals)),
            position = position_stack(vjust = .5), vjust = 4, color = "white", fontface = "bold") +
  geom_text(aes(total, year, label = sprintf("%1.0f%%", 1*prop), fill = NULL), hjust = -.2) +
  geom_curve(x = 710, y = 1.65, xend = 650, yend = 2,    
             arrow = arrow(), color = "#C2C2C2", linewidth = .2) +
  geom_curve(x = 870, y = 1.45, xend = 910, yend = 1.05, 
             arrow = arrow(), color = "#C2C2C2", linewidth = .2, curvature = -0.2) +
  scale_fill_manual(values = c("#E2E2E2", "#C2C2C2", "#8A8A8A", "#474747", "#F27575")) +
  theme_minimal() +
  theme(legend.position     = "none",
        axis.text.x         = element_blank(),
        axis.text.y         = element_text(face="bold", size = 8),
        panel.grid.major    = element_blank(), 
        panel.grid.minor    = element_blank(),
        plot.title.position = "plot",
        plot.margin         = margin(
          t = 0,    # Top margin
          r = 0,    # Right margin
          b = 0,    # Bottom margin
          l = 0)) + # Left margin
  labs(# title    = "Mothers' transition rate into primary-earning",
       # subtitle = "by SIPP panel and pathway",
       x        = " ", 
       y        = " ") +
  annotate("text", x = 780, y = 1.55, label = "Bars are scaled to the \naverage annual rate of transition", size = 8/.pt, color = "#C2C2C2") 

fig1

ggsave(filename = file.path(figDir, "fig1.png"), fig1, width=6.5, height=3.5, units="in", dpi=300, bg = 'white')


# FIGURE 2 #####################################################################

## Define color palette --------------------------------------------------------
c_palette <- c("#EF4868", "#474747", "#8A8A8A", "#C2C2C2", "#E2E2E2")

### create function to color strip text
strip_palette <- strip_themed(
  # Vertical strips
  text_y = elem_list_text(colour = c(c_palette),
                          by_layer_y = FALSE))

## Wrangle the data ------------------------------------------------------------

data_f2$group <- factor(data_f2$group, 
                        levels = c("Hispanic", "NH Asian", "Black", "NH White", "  ",
                                   "College Plus", "Some College",  "HS Degree or Less", " ",
                                   "Total"), ordered = FALSE)

data_f2$event <- factor(data_f2$event, 
                        levels = c("Partner separation",
                                   "Mothers earnings increased", "Partners earnings decreased",
                                   "Mothers earnings increased & partners earnings decreased",
                                   "Other member exit or earnings decreased"), ordered = FALSE)

levels(data_f2$event)[levels(data_f2$event)=="Mothers earnings increased & partners earnings decreased"] <- "Mothers earnings increased & \npartners earnings decreased"


## Create Figure  --------------------------------------------------------------
fig2 <- ggplot(data_f2, aes(x=group, y=vals)) +
  geom_segment( aes(x=group, xend=group, y=0, yend=vals), color="#474747") +
  geom_point( aes(color=event), size=3) +
  geom_hline(yintercept = 0) +
  ggh4x::facet_grid2(rows   = vars(event), switch = "y", strip = strip_palette) +
  coord_flip() +
  scale_color_manual(values = c(c_palette)) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  scale_x_discrete(drop=FALSE) +
  theme_minimal() +
  theme(
    panel.grid.major.y  = element_blank(),
    panel.border        = element_blank(),
    panel.spacing       = unit(1.2, "lines"),
    axis.ticks.y        = element_blank(),
    legend.position     = "none",
    strip.placement     = "outside",
    strip.text.y.left   = element_markdown(angle = 0, face = "bold"),
    plot.title.position = "plot") +
  labs(# title = "Total amount of the growth in maternal primary-earning explained",
    # subtitle = "by each pathway and disaggregated by demographic group",
    x    = " ", 
    y    = "% explained") 

fig2

ggsave(filename = file.path(figDir, "fig2.png"), fig2, width=6, height=9, units="in", dpi=300, bg = 'white')
