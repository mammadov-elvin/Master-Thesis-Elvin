# GRIP4 Global Roads Inventory Project - Data açma skripti

# ── Paketlər ──────────────────────────────────────────────────────────────────
required_packages <- c("sf", "dplyr", "ggplot2", "readxl")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

library(sf)
library(dplyr)
library(ggplot2)
library(readxl)

# ── Fayl yolunu dəyişin ───────────────────────────────────────────────────────
# Faylların olduğu qovluğu buraya yazın:
data_dir <- "C:/Users/User/Desktop/Thesis/Master Thesis Elvin/Data/region roads sovieet"   # <-- öz yolunuzu yazın

shp_path  <- file.path(data_dir, "GRIP4_region5.shp")
xlsx_path <- file.path(data_dir, "GRIP4_AttributeDescription.xlsx")

# ── 1. Attribute təsviri ──────────────────────────────────────────────────────
message("Attribute açıqlamaları oxunur...")
attr_desc <- read_excel(xlsx_path)
print(attr_desc)

# ── 2. Shapefile aç ───────────────────────────────────────────────────────────
message("Shapefile yüklənir (böyük fayl, bir az gözləyin)...")
roads <- st_read(shp_path)

message(paste("Ümumi yol sayı:", nrow(roads)))
message(paste("CRS (koordinat sistemi):", st_crs(roads)$input))

# Sütunlara bax
cat("\n--- Sütunlar ---\n")
glimpse(roads)

# ── 3. GRIP4 yol tipləri ──────────────────────────────────────────────────────
# GP_RTP sütunu yol tipini göstərir:
# 1 = Highway/Motorway
# 2 = Primary road
# 3 = Secondary road
# 4 = Tertiary road
# 5 = Local/Other road

road_type_labels <- c(
  "1" = "Magistral/Avtomobil yolu",
  "2" = "Əsas yol",
  "3" = "İkinci dərəcəli yol",
  "4" = "Üçüncü dərəcəli yol",
  "5" = "Yerli/Digər yol"
)

if ("GP_RTP" %in% names(roads)) {
  cat("\n--- Yol tipi üzrə say ---\n")
  print(table(roads$GP_RTP))
}

# ── 4. Azərbaycan üçün filtrələ ───────────────────────────────────────────────
# GRIP4-də ölkə kodu sütunu GP_COU (ISO 3166 numeric) və ya
# GP_ISO sütunu (ISO 3166 alpha-3) ola bilər
# Azərbaycan: ISO = AZE, numeric = 31

az_roads <- NULL

if ("GP_ISO" %in% names(roads)) {
  az_roads <- roads |> filter(GP_ISO == "AZE")
} else if ("GP_COU" %in% names(roads)) {
  az_roads <- roads |> filter(GP_COU == 31)
} else {
  # Azərbaycan bbox ilə kəs (lon: 44.8-50.4, lat: 38.4-41.9)
  az_bbox <- st_bbox(c(xmin = 44.8, ymin = 38.4,
                        xmax = 50.4, ymax = 41.9),
                     crs = st_crs(4326))
  az_roads <- st_crop(roads, az_bbox)
}

message(paste("Azərbaycan yolları:", nrow(az_roads)))

# ── 5. Nəticəni saxla ─────────────────────────────────────────────────────────
dir.create("data", showWarnings = FALSE)

st_write(az_roads, "data/grip4_azerbaijan.gpkg",
         delete_dsn = TRUE, quiet = TRUE)
message("Saxlanıldı: data/grip4_azerbaijan.gpkg")

write.csv(st_drop_geometry(az_roads),
          "data/grip4_azerbaijan.csv",
          row.names = FALSE,
          fileEncoding = "UTF-8")
message("Saxlanıldı: data/grip4_azerbaijan.csv")

# ── 6. Xəritə ─────────────────────────────────────────────────────────────────
if (nrow(az_roads) > 0) {

  road_colors <- c("1" = "#e41a1c", "2" = "#ff7f00",
                   "3" = "#4daf4a", "4" = "#377eb8", "5" = "#999999")

  p <- ggplot(az_roads) +
    geom_sf(aes(color = factor(GP_RTP)), linewidth = 0.4, alpha = 0.8) +
    scale_color_manual(values = road_colors,
                       labels = road_type_labels,
                       name   = "Yol növü",
                       na.value = "grey50") +
    labs(
      title    = "Azərbaycan - GRIP4 Yol Şəbəkəsi",
      subtitle = "Global Roads Inventory Project, Region 5",
      caption  = "Mənbə: GRIP4 (Meijer et al., 2018)"
    ) +
    theme_minimal() +
    theme(
      plot.title    = element_text(face = "bold", size = 14),
      legend.position = "right"
    )

  ggsave("data/grip4_azerbaijan_map.png", p,
         width = 10, height = 7, dpi = 300)
  message("Xəritə saxlanıldı: data/grip4_azerbaijan_map.png")

  print(p)
}
