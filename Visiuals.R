# ---------------------------------------------------------
# 1. Maximum NTL for each pixel, 2013–2020
# ---------------------------------------------------------

ntl_map <- panel_long %>%
  group_by(pixel_id, x, y) %>%
  summarise(
    ntl_max = max(ntl, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_ntl_max = log1p(ntl_max)
  )


# ---------------------------------------------------------
# 2. Minimum and maximum values
# ---------------------------------------------------------

ntl_min <- min(
  ntl_map$log_ntl_max,
  na.rm = TRUE
)

ntl_max_value <- max(
  ntl_map$log_ntl_max,
  na.rm = TRUE
)


# ---------------------------------------------------------
# 3. Convert pixels to spatial points
# ---------------------------------------------------------

ntl_map_sf <- st_as_sf(
  ntl_map,
  coords = c("x", "y"),
  crs = 4326,
  remove = FALSE
)


# ---------------------------------------------------------
# 4. Excluded districts
# ---------------------------------------------------------

excluded_area_map <- aze_sf %>%
  filter(Name_AZ %in% excluded_districts) %>%
  st_make_valid()


# ---------------------------------------------------------
# 5. Azerbaijan outline
# ---------------------------------------------------------

aze_outline <- aze_sf %>%
  st_make_valid() %>%
  summarise()


# =========================================================
# 6. PLOT
# =========================================================

ntl_figure <- ggplot() +
  
  # Base map
  geom_sf(
    data = aze_sf,
    fill = "grey95",
    color = "grey75",
    linewidth = 0.15
  ) +
  
  # Nighttime light pixels
  geom_sf(
    data = ntl_map_sf,
    aes(color = log_ntl_max),
    size = 0.35,
    alpha = 0.9
  ) +
  
  # Excluded districts
  geom_sf(
    data = excluded_area_map,
    aes(fill = "Excluded conflict-affected districts"),
    color = "black",
    linewidth = 0.20
  ) +
  
  # National border
  geom_sf(
    data = aze_outline,
    fill = NA,
    color = "black",
    linewidth = 0.50
  ) +
  
  # -------------------------------------------------------
# ORIGINAL INFERNO COLOUR SCALE
# -------------------------------------------------------

scale_color_viridis_c(
  option = "inferno",
  
  limits = c(
    ntl_min,
    ntl_max_value
  ),
  
  breaks = c(
    ntl_min,
    ntl_max_value
  ),
  
  labels = c(
    paste0(
      "Min: ",
      round(ntl_min, 2)
    ),
    paste0(
      "Max: ",
      round(ntl_max_value, 2)
    )
  ),
  
  name = "Log(1 + Max NTL)"
) +
  
  # -------------------------------------------------------
# Excluded districts legend
# -------------------------------------------------------

scale_fill_manual(
  name = NULL,
  values = c(
    "Excluded conflict-affected districts" = "black"
  )
) +
  
  # -------------------------------------------------------
# Title
# -------------------------------------------------------

labs(
  title =
    "Maximum Nighttime Light Intensity in Azerbaijan, 2013–2020"
) +
  
  # -------------------------------------------------------
# Legends
# -------------------------------------------------------

guides(
  
  color = guide_colorbar(
    order = 1,
    title.position = "top",
    title.hjust = 0.5,
    barheight = unit(6, "cm"),
    barwidth = unit(0.7, "cm")
  ),
  
  fill = guide_legend(
    order = 2,
    override.aes = list(
      color = "black"
    )
  )
) +
  
  # -------------------------------------------------------
# Theme
# -------------------------------------------------------

theme_void() +
  
  theme(
    
    plot.title = element_text(
      size = 13,
      face = "bold",
      hjust = 0.5,
      margin = margin(b = 10)
    ),
    
    legend.position = "right",
    
    legend.title = element_text(
      size = 10,
      face = "bold"
    ),
    
    legend.text = element_text(
      size = 9
    ),
    
    legend.spacing.y = unit(
      0.5,
      "cm"
    ),
    
    plot.margin = margin(
      10,
      10,
      10,
      10
    )
  )


# Show figure
ntl_figure


# =========================================================
# 7. SAVE FOR WORD — HIGH QUALITY PNG
# =========================================================

dir.create(
  here("Figures"),
  showWarnings = FALSE
)

ggsave(
  filename = here(
    "Figures",
    "maximum_ntl_azerbaijan_2013_2020.png"
  ),
  plot = ntl_figure,
  width = 20,
  height = 13,
  units = "cm",
  dpi = 300,
  bg = "white"
)